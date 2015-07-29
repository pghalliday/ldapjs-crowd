Q = require 'q'
chai = require 'chai'
chai.should()

gitlab = require '../../mock/gitlab'
ldap = require '../../mock/ldap'

LDAP_PORT = 4000
LDAP_URL = 'ldap://localhost:' + LDAP_PORT
SUFFIX = 'o=example'
UID = 'uid'
BIND_DN = 'cn=root,' + SUFFIX
PASSWORD = 'password'
BASE = 'ou=crowd,' + SUFFIX

describe 'gitlab', ->
  server = undefined
  client = undefined

  beforeEach ->
    server = ldap.createServer SUFFIX
    Q()
      .then ->
        server.listen LDAP_PORT
      .then ->
        client = gitlab.createClient
          url: LDAP_URL
          uid: UID
          bindDn: BIND_DN
          password: PASSWORD
          base: BASE

  afterEach ->
    server.close()

  describe '#authenticate', ->
    it 'should make the correct sequence of LDAP calls', ->
      client.authenticate
        username: 'test'
        password: 'secret'
      .then ->
        server.calls.should.eql [
          route: 'bind'
          request:
            version: 3
            name: BIND_DN
            authentication: 'simple'
            credentials: PASSWORD
        ,
          route: 'search'
          request:
            baseObject: BASE
            scope: 'sub'
            derefAliases: 0
            sizeLimit: 1
            timeLimit: 10
            typesOnly: false
            filter: '(uid=test)'
            attributes: ''
        ,
          route: 'bind'
          request:
            version: 3
            name: 'uid=test,' + BASE
            authentication: 'simple'
            credentials: 'secret'
        ,
          route: 'bind'
          request:
            version: 3
            name: BIND_DN
            authentication: 'simple'
            credentials: PASSWORD
        ,
          route: 'search'
          request:
            baseObject: 'uid=test,' + BASE
            scope: 'base'
            derefAliases: 0
            sizeLimit: 0
            timeLimit: 10
            typesOnly: false
            filter: '(objectclass=*)'
            attributes: ''
        ]
