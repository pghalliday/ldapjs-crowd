Q = require 'q'
http = require 'http'
express = require 'express'
basicAuth = require 'basic-auth-connect'

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
    @app = express @server
    @server = http.createServer @app
    @app.use basicAuth @params.applicationName, @params.applicationPassword

    @app.get '/crowd/rest/usermanagement/1/user', (req, res) =>
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

  listen: (port) ->
    Q.ninvoke @server, 'listen', port

  close: ->
    Q.ninvoke @server, 'close'

module.exports.createServer = (params) ->
  new Crowd params
