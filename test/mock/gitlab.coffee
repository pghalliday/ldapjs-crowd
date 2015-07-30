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

    it 'should throw an error if the first bind fails', ->
      server.failOnBind 0
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /first bind failed/

    it 'should throw an error if the first search fails', ->
      server.failOnSearch 0
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /first search failed/

    it 'should throw an error if no match is returned from the first search', ->
      server.noMatchOnSearch 0
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /first search found no match/

    it 'should throw an error if the second bind fails', ->
      server.failOnBind 1
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /second bind failed/

    it 'should throw an error if the third bind fails', ->
      server.failOnBind 2
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /third bind failed/

    it 'should throw an error if the second search fails', ->
      server.failOnSearch 1
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /second search failed/

    # coffeelint: disable=max_line_length
    it 'should throw an error if no match is returned from the second search', ->
    # coffeelint: enable=max_line_length
      server.noMatchOnSearch 1
      client.authenticate
        username: 'test'
        password: 'secret'
      .should.be.rejectedWith /second search found no match/
