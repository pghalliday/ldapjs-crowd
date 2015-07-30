Q = require 'q'
ldapjs = require 'ldapjs'

class Ldap
  constructor: (suffix) ->
    @failOnBindOffset = 0
    @forceFailOnBind = false
    @failOnSearchOffset = 0
    @forceFailOnSearch = false
    @noMatchOnSearchOffset = 0
    @forceNoMatchOnSearch = false
    @calls = []
    @server = ldapjs.createServer()

    @server.bind suffix, (req, res, next) =>
      if @forceFailOnBind
        if @failOnBindOffset is 0
          return next new ldapjs.OtherError 'forced fail'
        else
          @failOnBindOffset--
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
      if @forceFailOnSearch
        if @failOnSearchOffset is 0
          return next new ldapjs.OtherError 'forced fail'
        else
          @failOnSearchOffset--
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
      if not @forceNoMatchOnSearch or @noMatchOnSearchOffset > 0
        res.send
          dn: 'cn=hello,' + req.dn.toString()
          attributes:
            email: 'hello@hello.com'
      if @forceNoMatchOnSearch and @noMatchOnSearchOffset > 0
        @noMatchOnSearchOffset--
      res.end()
      next()

  listen: (port) =>
    Q.ninvoke @server, 'listen', port

  close: =>
    deferred = Q.defer()
    @server.on 'close', deferred.resolve
    @server.close()
    deferred.promise

  failOnBind: (offset) =>
    @forceFailOnBind = true
    @failOnBindOffset = offset || 0

  failOnSearch: (offset) =>
    @forceFailOnSearch = true
    @failOnSearchOffset = offset || 0

  noMatchOnSearch: (offset) =>
    @forceNoMatchOnSearch = true
    @noMatchOnSearchOffset = offset || 0

module.exports.createServer = (suffix) ->
  new Ldap suffix
