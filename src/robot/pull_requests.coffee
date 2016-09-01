# Description:
#   A hubot script that provides GitHub pull request information
#
# Commands:
#   hubot prs - Displays a list of open pull requests for all repositories
#   hubot prs (for) <repo_name> - Displays a list of open pull requests for a repository
#
# Author:
#   brianberg

Promise = require 'bluebird'
octocat = require '../octocat'

# Box drawing characters
BOX_LINE = '─'
BOX_LINE_DOWN = '┬'
BOX_LINE_VERT_RIGHT = '├'
BOX_BOT_LEFT = '└'

OCTONODE_ERROR_NOT_FOUND = "Error: Not Found"

module.exports = (robot) ->

  # Show open pull requests
  robot.respond /(show\s)?(prs|pull\srequests)(\sfor)?\s?(.*)?/i, (msg) ->

    repo_name = msg.match[4]
    if repo_name?
      octocat.getPullRequests(repo_name)
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
      msg.send "Searching repositories..."
      octocat.getRepos()
        .then (repos) ->
          Promise.reduce(repos, pullRequestReducer, {}).then (pull_requests) ->
            keys = Object.keys pull_requests
            if keys.length is 0
              msg.send "There are no open pull requests."
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
      return octocat.getPullRequests(repo.full_name)
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
      line = BOX_LINE_DOWN + Array(title.length).join(BOX_LINE)
      msg.send "\n#{ title }\n#{ line }"

    # Post pull request details
    postPullRequest = (pr, is_last) ->
      assigned = if pr.assignee.login then pr.assignee.login else "unassigned"
      url = pr.html_url.replace(/.*?:\/\//g, "")
      bullet = if is_last then BOX_BOT_LEFT else BOX_LINE_VERT_RIGHT
      msg.send "#{bullet + BOX_LINE } ##{ pr.number } #{ pr.title } » #{ assigned } @ #{ url }"

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
