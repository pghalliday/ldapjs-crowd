Q = require 'q'
chai = require 'chai'
chai.should()

ldapjsCrowd = require '../../src/'
ldapjs = require 'ldapjs'

crowd = require '../../mock/crowd'
gitlab = require '../../mock/gitlab'

CROWD_PORT = 3000
CROWD_URL = 'http://localhost:' + CROWD_PORT
APPLICATION_NAME = 'test'
APPLICATION_PASSWORD = 'password'

LDAP_PORT = 4000
LDAP_URL = 'ldap://localhost:' + LDAP_PORT

SUFFIX = 'o=example'

describe 'ldapjs-crowd', ->
  server = ldapjs.createServer()
  backend = ldapjsCrowd.createBackend
    crowdUrl: CROWD_URL
    applicationName: APPLICATION_NAME
    applicationPassword: APPLICATION_PASSWORD
  server.add SUFFIX, backend.add
  server.modify SUFFIX, backend.modify
  server.modifyDN SUFFIX, backend.modifyDN
  server.bind SUFFIX, backend.bind
  server.compare SUFFIX, backend.compare
  server.del SUFFIX, backend.del
  server.search SUFFIX, backend.search

  before ->
    Q()
      .then ->
        crowd.listen CROWD_PORT
      .then ->
        Q.ninvoke server, 'listen', LDAP_PORT

  after ->
    deferred = Q.defer()
    server.on 'close', deferred.resolve
    server.close()
    deferred.promise
      .then ->
        crowd.close()

  it 'should support bind', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.bind 'cn=john, ' + SUFFIX, 'secret'
      .then ->
        client.unbind()

  it 'should support add', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.add SUFFIX,
          cn: 'foo'
      .then ->
        client.unbind()

  it 'should support modify', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.modify SUFFIX,
          operation: 'add'
          modification:
            pets: ['cat', 'dog']
      .then ->
        client.unbind()

  it 'should support modifyDN', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.modifyDN 'cn=foo, ' + SUFFIX, 'cn=bar'
      .then ->
        client.unbind()

  it 'should support compare', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.compare 'cn=foo, ' + SUFFIX, 'sn', 'bar'
      .then ->
        client.unbind()

  it 'should support del', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.del 'cn=foo, ' + SUFFIX
      .then ->
        client.unbind()

  it 'should support search', ->
    client = gitlab.createClient LDAP_URL
    Q()
      .then ->
        client.search SUFFIX,
          filter: '(&(l=Seattle)(email=*@foo.com))'
          scope: 'sub'
      .then ->
        client.unbind()
