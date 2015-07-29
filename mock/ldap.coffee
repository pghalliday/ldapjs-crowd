Q = require 'q'
ldapjs = require 'ldapjs'

class Ldap
  constructor: (suffix) ->
    @calls = []
    @server = ldapjs.createServer()

    @server.bind suffix, (req, res, next) =>
      @calls.push
        route: 'bind'
        request:
          version: req.version
          name: req.name.toString()
          authentication: req.authentication
          credentials: req.credentials
      res.end()
      next()

    @server.search suffix, (req, res, next) =>
      @calls.push
        route: 'search'
        request:
          baseObject: req.baseObject.toString()
          scope: req.scope
          derefAliases: req.derefAliases
          sizeLimit: req.sizeLimit
          timeLimit: req.timeLimit
          typesOnly: req.typesOnly
          filter: req.filter.toString()
          attributes: req.attributes.toString()
      res.end()
      next()

  listen: (port) =>
    Q.ninvoke @server, 'listen', port

  close: =>
    deferred = Q.defer()
    @server.on 'close', deferred.resolve
    @server.close()
    deferred.promise

module.exports.createServer = (suffix) ->
  new Ldap suffix
