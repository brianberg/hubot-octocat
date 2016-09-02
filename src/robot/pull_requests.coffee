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

# Colors
COLOR_DARK_BLUE = "#4078C0"
COLOR_LIGHT_BLUE = "#D4E0F1"

OCTONODE_ERROR_NOT_FOUND = "Error: Not Found"

module.exports = (robot) ->

  # Show open pull requests
  robot.respond /(show\s)?(prs|pull\srequests)(\sfor)?\s?(.*)?/i, (res) ->

    repo_name = res.match[4]
    if repo_name?
      octocat.getPullRequests(repo_name)
        .then (results) ->
          postSummary results.length
          if octocat.usingAdapter robot, 'slack'
            attachments = []
            attachments.push createRepoHeaderAttachment(repo_name)
            for pr in results
              attachments.push createPullRequestAttachment(pr)
            res.send {
              attachments : attachments,
              username    : robot.name,
              as_user     : true
            }
          else
            postRepoHeader(results[0].head.repo.full_name) if results.length > 0
            postPullRequests results
        .catch (error) ->
          handlePRError error, repo_name
    else
      res.send "Searching repositories..."
      octocat.getRepos()
        .then (repos) ->
          Promise.reduce(repos, pullRequestReducer, {}).then (pull_requests) ->
            keys = Object.keys pull_requests
            postSummary keys.length
            keys.sort()
            if octocat.usingAdapter robot, 'slack'
              attachments = []
              for k in keys
                attachments.push createRepoHeaderAttachment(k)
                attachments.push createPullRequestAttachment(pull_requests[k])
              res.send {
                attachments : attachments,
                username    : robot.name,
                as_user     : true
              }
            else
              for k in keys
                postRepoHeader k
                postPullRequests pull_requests[k]
        .catch (error) ->
          res.send "Unable to retreive repositories, please verify your credentials."

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

    # Post summary of the number of open pull requests
    postSummary = (count) ->
      if count is 0
        res.send "There are no open pull requests."
      else
        is_singular = count is 1
        res.send "There #{ if is_singular then 'is' else 'are' } #{ count } open pull request" +
          "#{ if !is_singular then 's' else '' }."

    # Post a list of pull requests
    postPullRequests = (requests) ->
      for r, index in requests
        is_last = index is requests.length - 1
        postPullRequest r, is_last

    # Post repository header
    postRepoHeader = (title) ->
      line = BOX_LINE_DOWN + Array(title.length).join(BOX_LINE)
      res.send "\n#{ title }\n#{ line }"

    # Post pull request details
    postPullRequest = (pr, is_last) ->
      parsed = octocat.parsePullRequest(pr)
      bullet = if is_last then BOX_BOT_LEFT else BOX_LINE_VERT_RIGHT
      res.send "#{ bullet + BOX_LINE } ##{ parsed.title } » #{ parsed.assigned } » updated #{ parsed.updated }"

    # Handle get pull requests erros
    handlePRError = (error, repo_name) ->
      if `error == OCTONODE_ERROR_NOT_FOUND` # Force loose comparison
        res.send "#{ repo_name } was not found. Is that the full name of the repository?"
      else
        res.send "Unable to retrieve pull requests for #{ repo_name }, please verify your credentials."

    # Create repository header attachment
    createRepoHeaderAttachment : (repo_name) ->
      return {
        color    : COLOR_DARK_BLUE,
        title    : repo_name,
        fallback : repo_name
      }

    # Create pull request attachment
    createPullRequestAttachment = (pr) ->
      parsed = octocat.parsePullRequest(pr)
      return {
        color        : COLOR_LIGHT_BLUE,
        author_name  : parsed.author.name,
        author_link  : parsed.author.link,
        author_icon  : parsed.author.icon,
        title        : parsed.title,
        title_link   : parsed.url,
        text         : parsed.text,
        fallback     : "##{ parsed.title } » #{ parsed.assigned } » updated #{ parsed.updated }"
        fields : [
          {
            title : "Assigned",
            value : parsed.assigned,
            short : true
          },
          {
            title : "Updated",
            value : parsed.updated,
            short : true
          }
        ]
      }

  # Error handling
  robot.error (err, res) ->
    robot.logger.error "DOES NOT COMPUTE"
    if res?
      res.reply "DOES NOT COMPUTE"
