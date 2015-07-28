Q = require 'q'
chai = require 'chai'
chai.should()

gitlab = require '../../mock/gitlab'
ldapjs = require 'ldapjs'

LDAP_PORT = 4000
LDAP_URL = 'ldap://localhost:' + LDAP_PORT
SUFFIX = 'o=example'

describe 'gitlab', ->
  server = ldapjs.createServer()
  server.bind SUFFIX, (req, res, next) ->
    res.end()
    next()
  server.add SUFFIX, (req, res, next) ->
    res.end()
    next()
  server.modify SUFFIX, (req, res, next) ->
    res.end()
    next()
  server.modifyDN SUFFIX, (req, res, next) ->
    res.end()
    next()
  server.compare SUFFIX, (req, res, next) ->
    res.end(false)
    next()
  server.del SUFFIX, (req, res, next) ->
    res.end()
    next()
  server.search SUFFIX, (req, res, next) ->
    res.end()
    next()

  before ->
    Q.ninvoke server, 'listen', LDAP_PORT

  after ->
    deferred = Q.defer()
    server.on 'close', deferred.resolve
    server.close()
    deferred.promise

  it 'should bind', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.bind SUFFIX, 'secret'
      .then ->
        client.unbind()

  it 'should add', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.add SUFFIX,
          cn: 'foo'
      .then ->
        client.unbind()

  it 'should modify', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.modify SUFFIX,
          operation: 'add'
          modification:
            pets: ['cat', 'dog']
      .then ->
        client.unbind()

  it 'should modifyDN', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.modifyDN 'cn=foo, ' + SUFFIX, 'cn=bar'
      .then ->
        client.unbind()

  it 'should compare', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.compare 'cn=foo, ' + SUFFIX, 'sn', 'bar'
      .then ->
        client.unbind()

  it 'should del', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.del 'cn=foo, ' + SUFFIX
      .then ->
        client.unbind()

  it 'should search', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.search SUFFIX,
          filter: '(&(l=Seattle)(email=*@foo.com))'
          scope: 'sub'
      .then ->
        client.unbind()
