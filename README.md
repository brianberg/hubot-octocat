# hubot-octocat

A hubot script that provides Github repository information

## Commands

* `hubot (show) prs`                   - Displays a list of open pull requests for all repositories
* `hubot (show) prs (for) <repo_name>` - Displays a list of open pull requests for a particular repository

## Installation

In hubot project repo, run:

`npm install hubot-octocat --save`

Then add **hubot-octocat** to your `external-scripts.json`:

```json
[
  "hubot-octocat"
]
```

## Configuration
The plugin depends on environment variables beginning with `HUBOT_OCTOCAT_`. The following configurations are available:

* `HUBOT_OCTOCAT_OAUTH_TOKEN` - (Required) A GitHub OAuth token
* `HUBOT_OCTOCAT_USER`        - A GitHub username
* `HUBOT_OCTOCAT_TEAM_ID`     - A GitHub Team ID, takes precedence over HUBOT_OCTOCAT_USER.
* `HUBOT_OCTOCAT_ORG`         - A GitHub organization name, takes precedence over HUBOT_OCTOCAT_TEAM_ID

A username, team ID, or organization name must be specified.

## Sample Interaction

```
user> hubot show prs
hubot> There are 3 open pull requests.

 org/awesome-project
─┬────────────────────
 ├─ #24 Fix all things » unassigned @ github.com/org/awesome-project/pulls/24
 └─ #27 Important change » someone @ github.com/org/awesome-project/pulls/27

 org/another-project
─┬───────────────────
 └─ #12 Fix all things » someone @ github.com/org/another-project/pulls/12
```

## NPM Module

https://www.npmjs.com/package/hubot-octocat
