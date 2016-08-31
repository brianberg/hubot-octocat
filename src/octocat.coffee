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
# Author:
#   brianberg

Promise  = require 'bluebird'
octonode = Promise.promisifyAll(require 'octonode')

# GitHub connection and user setup
github = octonode.client(process.env.HUBOT_OCTOCAT_OAUTH_TOKEN)
if process.env.HUBOT_OCTOCAT_ORG
  github_conn = github.org process.env.HUBOT_OCTOCAT_ORG
else if process.env.HUBOT_OCTOCAT_TEAM_ID
  github_conn = github.team process.env.HUBOT_OCTOCAT_TEAM_ID
else if process.env.HUBOT_OCTOCAT_USER
  github_conn = github.user process.env.HUBOT_OCTOCAT_USER

module.exports =

  # Get open pull requests for a particular repository
  getPullRequests : (repo_name) ->
    if !github_conn
      return Promise.reject("Invalid GitHub connection")
    return github.repo(repo_name).prsAsync(state : 'open', sort : 'create')

  # Get all repositories
  getRepos : ->
    return github_conn.reposAsync()
