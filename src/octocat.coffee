# Description:
#   A hubot script that provides GitHub repository information
#
# Dependencies:
#   "bluebird": "^3.4.3",
#   "octonode": "^0.7.6"
#
# Configuration:
#   HUBOT_OCTOCAT_OAUTH_TOKEN = # (Required) A GitHub OAuth token generated from your account
#   HUBOT_OCTOCAT_USER = # (Required if HUBOT_OCTOCAT_TEAM_ID or HUBOT_OCTOCAT_ORG is not set) A GitHub username
#   HUBOT_OCTOCAT_TEAM_ID = # (Required if HUBOT_OCTOCAT_USER is not set) A GitHub Team ID, takes precedence over HUBOT_OCTOCAT_USER.
#   HUBOT_OCTOCAT_ORG = # (Required if HUBOT_OCTOCAT_USER or HUBOT_OCTOCAT_TEAM_ID is not set) A GitHub organization, takes precedence over HUBOT_OCTOCAT_TEAM_ID
#
# Commands:
#   hubot show prs - Displays a list of open pull requests for all repositories
#   hubot show prs <repo_full_name> - Displays a list of open pull requests for a particular repository
#
# Author:
#   brianberg

Promise = require 'bluebird'
octonode = Promise.promisifyAll(require 'octonode')

# Box drawing characters
BOX_LINE = '─'
BOX_LINE_DOWN = '┬'
BOX_LINE_VERT_RIGHT = '├'
BOX_BOT_LEFT = '└'

OCTONODE_ERROR_NOT_FOUND = "Error: Not Found"

# GitHub connection and user setup
github = octonode.client(process.env.HUBOT_OCTOCAT_OAUTH_TOKEN)
if process.env.HUBOT_OCTOCAT_ORG
  github_conn = github.org process.env.HUBOT_OCTOCAT_ORG
else if process.env.HUBOT_OCTOCAT_TEAM_ID
  github_conn = github.team process.env.HUBOT_OCTOCAT_TEAM_ID
else if process.env.HUBOT_OCTOCAT_USER
  github_conn = github.user process.env.HUBOT_OCTOCAT_USER

# Get open pull requests for a particular repository
getPullRequests = (repo_name) ->
  github_repo = github.repo repo_name
  return github_repo.prsAsync(state : 'open', sort : 'create')

module.exports = (robot) ->

  # Show open pull requests
  robot.respond /(show\s)?(prs|pull requests)(\sfor\s)?(.*)?/i, (msg) ->

    # Short circuit if there is no GitHub connection
    if !github_conn
      msg.send "Unable to obtain GitHub connection, please verify your credentials."
      return

    repo_name = msg.match[4]
    if repo_name?
      getPullRequests(repo_name)
        .then (results) ->
          if results.length is 0
            msg.send "There are no open pull requests for #{ repo_name }."
          else
            is_singular = results.length is 1
            msg.send "There #{ if is_singular then 'is' else 'are' } #{ results.length } open pull request" +
              "#{ if !is_singular then 's' else '' } for #{ repo_name }."
            postRepoHeader(results[0].head.repo.full_name) if results.length > 0
            postPullRequests results
        .catch (error) ->
          handlePRError error, repo_name
    else
      github_conn.reposAsync()
        .then (repos) ->
          Promise.reduce(repos, pullRequestReducer, {}).then (pull_requests) ->
            keys = Object.keys pull_requests
            if keys.length is 0
              msg.send "There are no open pull requests, get to work!"
            else
              is_singular = keys.length is 1
              msg.send "There #{ if is_singular then 'is' else 'are' } #{ keys.length } open pull request" +
                "#{ if !is_singular then 's' else }."
              keys.sort()
              for k in keys
                postRepoHeader k
                postPullRequests pull_requests[k]
        .catch (error) ->
          msg.send "Unable to retreive repositories, please verify your credentials."

    # Maps pull requests by repository and counts total
    pullRequestReducer = (pull_requests, repo) ->
      return getPullRequests(repo.full_name)
        .then (results) ->
          if results.length > 0
            pull_requests[results[0].head.repo.full_name] = results
          return pull_requests
        .catch (error) ->
          handlePRError error, repo.full_name
          return pull_requests

    # Post a list of pull requests
    postPullRequests = (requests) ->
      if requests.length > 0
        for r, index in requests
          is_last = index is requests.length - 1
          postPullRequest r, is_last

    # Post repository header
    postRepoHeader = (title) ->
      line = BOX_LINE + BOX_LINE_DOWN + Array(title.length + 1).join(BOX_LINE)
      msg.send "\n #{ title } \n#{ line }"

    # Post pull request details
    postPullRequest = (pr, is_last) ->
      assigned = if pr.assignee.login then pr.assignee.login else "unassigned"
      url = pr.html_url.replace(/.*?:\/\//g, "")
      bullet = if is_last then BOX_BOT_LEFT else BOX_LINE_VERT_RIGHT
      msg.send " #{bullet + BOX_LINE } ##{ pr.number } #{ pr.title } » #{ assigned } @ #{ url }"

    # Handle get pull requests erros
    handlePRError = (error, repo_name) ->
      if `error == OCTONODE_ERROR_NOT_FOUND` # Force loose comparison
        msg.send "#{ repo_name } was not found. Is this the full name of the repository?"
      else
        msg.send "Unable to retrieve pull requests for #{ repo_name }, please verify your credentials."

  # Error handling
  robot.error (err, msg) ->
    robot.logger.error "DOES NOT COMPUTE"
    if msg?
      msg.reply "DOES NOT COMPUTE"
