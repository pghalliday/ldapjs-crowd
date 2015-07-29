Q = require 'q'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
chai.should()
chai.use chaiAsPromised

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
UID = 'uid'
BIND_DN = 'cn=root'
PASSWORD = 'password'
BASE = 'ou=crowd'

SUFFIX = 'o=example'

describe 'ldapjs-crowd', ->
  server = ldapjs.createServer()
  backend = ldapjsCrowd.createBackend
    crowd:
      url: CROWD_URL
      applicationName: APPLICATION_NAME
      applicationPassword: APPLICATION_PASSWORD
    ldap:
      uid: UID
      dnSuffix: SUFFIX
      bindDn: BIND_DN
      bindPassword: PASSWORD
      searchBase: BASE
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

  describe 'routes', ->
    client = undefined

    beforeEach ->
      client = ldapjs.createClient
        url: LDAP_URL

    afterEach ->
      Q.ninvoke client, 'unbind'

    it 'should support bind', ->
      Q()
        .then ->
          Q.ninvoke client, 'bind', 'cn=john, ' + SUFFIX, 'secret'

    it 'should support search', ->
      Q()
        .then ->
          Q.ninvoke client, 'search', SUFFIX,
            filter: '(&(l=Seattle)(email=*@foo.com))'
            scope: 'sub'

    it 'should not support add', ->
      Q()
        .then ->
          Q.ninvoke client, 'add', SUFFIX,
            cn: 'foo'
        .should.be.rejectedWith(/not implemented/)

    it 'should not support modify', ->
      Q()
        .then ->
          Q.ninvoke client, 'modify', SUFFIX,
            operation: 'add'
            modification:
              pets: ['cat', 'dog']
        .should.be.rejectedWith(/not implemented/)

    it 'should not support modifyDN', ->
      Q()
        .then ->
          Q.ninvoke client, 'modifyDN', 'cn=foo, ' + SUFFIX, 'cn=bar'
        .should.be.rejectedWith(/not implemented/)

    it 'should not support compare', ->
      Q()
        .then ->
          Q.ninvoke client, 'compare', 'cn=foo, ' + SUFFIX, 'sn', 'bar'
        .should.be.rejectedWith(/not implemented/)

    it 'should not support del', ->
      Q()
        .then ->
          Q.ninvoke client, 'del', 'cn=foo, ' + SUFFIX
        .should.be.rejectedWith(/not implemented/)
