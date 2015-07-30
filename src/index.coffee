Q = require 'q'
ldapjs = require 'ldapjs'
CrowdClient = require 'atlassian-crowd-client'

class CrowdBackend
  constructor: (@params) ->
    @crowd = new CrowdClient
      baseUrl: @params.crowd.url
      application:
        name: @params.crowd.applicationName
        password: @params.crowd.applicationPassword
    @bindDn =
      ldapjs.parseDN @params.ldap.bindDn + ',' + @params.ldap.dnSuffix
    @searchBase =
      ldapjs.parseDN @params.ldap.searchBase + ',' + @params.ldap.dnSuffix

  createSearchEntry: (user) =>
    attributes = Object.create null
    attributes[@params.ldap.uid] = user.name
    attributes.givenName = user.firstname
    attributes.sn = user.lastname
    attributes.displayName = user.displayname
    attributes.mail = user.email
    dn: @params.ldap.uid + '=' + user.name + ',' + @searchBase
    attributes: attributes

  authorize: (req, red, next) =>
    if not req.connection.ldap.bindDN.equals @bindDn
      return next new ldapjs.InsufficientAccessRightsError
    next()

  authorizeThen: (next) => [@authorize, next]

  bind: => (req, res, next) =>
    if req.dn.equals @bindDn
      if req.credentials isnt @params.ldap.bindPassword
        return next new ldapjs.InvalidCredentialsError()
    else if req.dn.childOf @searchBase
    else
      return next new ldapjs.InvalidCredentialsError()
    res.end()
    next()

  search: => @authorizeThen (req, res, next) =>
    promised = false
    deferred = Q.defer()
    deferred.promise.then ->
      res.end()
      next()
    .done()
    if req.dn.equals @searchBase
      if req.filter instanceof ldapjs.EqualityFilter
        if req.filter.attribute is @params.ldap.uid
          promised = true
          Q(@crowd.user.get(req.filter.value))
            .then (user) =>
              if user.active
                res.send @createSearchEntry user
              deferred.resolve()
            .catch (error) ->
              deferred.resolve()
            .done()
    else if req.dn.childOf @searchBase
      promised = true
      deferred.resolve()
    else
      return next new ldapjs.NoSuchObjectError()
    if not promised
      deferred.resolve()

module.exports.createBackend = (params) ->
  new CrowdBackend params
