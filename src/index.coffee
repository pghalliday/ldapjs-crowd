Q = require 'q'
ldapjs = require 'ldapjs'
CrowdClient = require 'atlassian-crowd-client'

getUidFromFilter = (filter, attribute) ->
  if filter.type is 'equal'
    if filter.attribute is attribute
      filter.value
    else
      null
  else if filter.type is 'and'
    filters = filter.filters
    uid = null
    index = 0
    while uid is null and index < filters.length
      uid = getUidFromFilter filters[index++], attribute
    uid
  else
    null

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
    attributes = {}
    attributes[@params.ldap.uid] = user.username
    attributes.givenName = user.firstname
    attributes.sn = user.lastname
    attributes.displayName = user.displayname
    attributes.mail = user.email
    attributes.objectclass = 'person'
    dn: @params.ldap.uid + '=' + user.username + ',' + @searchBase
    attributes: attributes

  authorize: (req, red, next) =>
    if not req.connection.ldap.bindDN.equals @bindDn
      return next new ldapjs.InsufficientAccessRightsError
    next()

  authorizeThen: (next) => [@authorize, next]

  bind: => (req, res, next) =>
    promised = false
    deferred = Q.defer()
    deferred.promise.then ->
      res.end()
      next()
    .catch (error) ->
      next new ldapjs.InvalidCredentialsError()
    .done()
    if req.dn.equals @bindDn
      if req.credentials isnt @params.ldap.bindPassword
        return next new ldapjs.InvalidCredentialsError()
    else if req.dn.childOf @searchBase
      rdns = req.dn.rdns
      return next new ldapjs.InvalidCredentialsError() if rdns.length isnt 3
      first = rdns[0].attrs
      uid = @params.ldap.uid
      return next new ldapjs.InvalidCredentialsError() if not first[uid]
      username = first[uid].value
      promised = true
      Q(@crowd.authentication.authenticate(username, req.credentials))
        .then ->
          deferred.resolve()
        .catch (error) ->
          deferred.reject error
        .done()
    else
      return next new ldapjs.InvalidCredentialsError()
    if not promised
      deferred.resolve()

  search: => @authorizeThen (req, res, next) =>
    promised = false
    deferred = Q.defer()
    deferred.promise.then ->
      res.end()
      next()
    .done()
    if req.dn.equals @searchBase
      if req.scope = 'sub'
        uid = getUidFromFilter req.filter, @params.ldap.uid
        if uid isnt null
          promised = true
          Q(@crowd.user.get(uid))
            .then (user) =>
              if user.active
                entry = @createSearchEntry user
                if req.filter.matches entry.attributes
                  res.send entry
              deferred.resolve()
            .catch ->
              deferred.resolve()
            .done()
    else if req.dn.childOf @searchBase
      rdns = req.dn.rdns
      if rdns.length is 3
        first = rdns[0].attrs
        uid = @params.ldap.uid
        if first[uid]
          username = first[uid].value
          if req.scope = 'base'
            promised = true
            Q(@crowd.user.get(username))
              .then (user) =>
                if user.active
                  res.send @createSearchEntry user
                deferred.resolve()
              .catch ->
                deferred.resolve()
              .done()
    else
      return next new ldapjs.NoSuchObjectError()
    if not promised
      deferred.resolve()

module.exports.createBackend = (params) ->
  new CrowdBackend params
