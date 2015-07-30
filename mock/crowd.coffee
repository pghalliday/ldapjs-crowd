Q = require 'q'
http = require 'http'
express = require 'express'
basicAuth = require 'basic-auth-connect'
bodyParser = require 'body-parser'

createUserObject = (user, active) ->
  object = Object.create null
  object.name = user.username
  object.active = active
  object['first-name'] = user.firstName
  object['last-name'] = user.lastName
  object['display-name'] = user.displayName
  object.email = user.email
  object

class Crowd
  constructor: (@params) ->
    @forceFailOnUser = false
    @failOnUserOffset = 0
    @app = express @server
    @server = http.createServer @app
    @app.use basicAuth @params.applicationName, @params.applicationPassword
    @app.use bodyParser.json()

    @app.get '/crowd/rest/usermanagement/1/user', (req, res) =>
      if @forceFailOnUser and @failOnUserOffset is 0
        res.status(404).end()
      else
        @failOnUserOffset-- if @forceFailOnUser
        if req.query.username is @params.activeUser.username
          json = JSON.stringify createUserObject @params.activeUser, true
          res
            .set('Content-Type', 'application/json')
            .send new Buffer json
        else if req.query.username is @params.inactiveUser.username
          json = JSON.stringify createUserObject @params.inactiveUser, false
          res
            .set('Content-Type', 'application/json')
            .send new Buffer json
        else
          res.status(404).end()

    @app.post '/crowd/rest/usermanagement/1/authentication', (req, res) =>
      if req.query.username is @params.activeUser.username
        if req.body.value is @params.activeUser.userPassword
          json = JSON.stringify createUserObject @params.activeUser, true
          res
            .set('Content-Type', 'application/json')
            .send new Buffer json
        else
          json = JSON.stringify
            reason: 'INVALID_USER_AUTHENTICATION'
            message: 'Username or password is invalid'
          res
            .set('Content-Type', 'application/json')
            .send new Buffer json
      else if req.query.username is @params.inactiveUser.username
        json = JSON.stringify
          reason: 'INACTIVE_ACCOUNT'
          message: 'Account is inactive'
        res
          .set('Content-Type', 'application/json')
          .send new Buffer json
      else
        res.status(404).end()

  failOnUser: (offset) =>
    @forceFailOnUser = true
    @failOnUserOffset = offset

  listen: (port) ->
    Q.ninvoke @server, 'listen', port

  close: ->
    Q.ninvoke @server, 'close'

module.exports.createServer = (params) ->
  new Crowd params
