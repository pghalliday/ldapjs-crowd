Q = require 'q'
chai = require 'chai'
chai.should()

ldapjs = require 'ldapjs'
ldap = require '../../mock/ldap'

SUFFIX = 'o=example'
PORT = 4000
URL = 'ldap://localhost:' + PORT

describe 'ldap', ->
  server = undefined
  client = undefined

  beforeEach ->
    server = ldap.createServer SUFFIX
    server.listen(PORT)
      .then ->
        client = ldapjs.createClient
          url: URL
        
  afterEach ->
    Q()
      .then ->
        Q.ninvoke client, 'unbind'
      .then ->
        server.close()

  it 'should record calls to bind', ->
    Q()
      .then ->
        Q.ninvoke client, 'bind', SUFFIX, 'secret'
      .then ->
        server.calls.should.eql [
          route: 'bind'
          request:
            version: 3
            authentication: 'simple'
            name: SUFFIX
            credentials: 'secret'
        ]

  it 'should record calls to search', ->
    Q()
      .then ->
        Q.ninvoke client, 'search', SUFFIX,
          filter: '(&(l=Seattle)(email=*@foo.com))'
          scope: 'sub'
      .then (res) ->
        deferred = Q.defer()
        res.on 'end', ->
          server.calls.should.eql [
            route: 'search'
            request:
              baseObject: SUFFIX
              scope: 'sub'
              derefAliases: 0
              sizeLimit: 0
              timeLimit: 10
              typesOnly: false
              filter: '(&(l=Seattle)(email=*@foo.com))'
              attributes: ''
          ]
          deferred.resolve()
        deferred.promise

  it 'should record the order of calls', ->
    Q()
      .then ->
        Q.ninvoke client, 'bind', SUFFIX, 'secret'
      .then ->
        Q.ninvoke client, 'search', SUFFIX,
          filter: '(&(l=Seattle)(email=*@foo.com))'
          scope: 'sub'
      .then (res) ->
        deferred = Q.defer()
        res.on 'end', ->
          server.calls.should.eql [
            route: 'bind'
            request:
              version: 3
              authentication: 'simple'
              name: SUFFIX
              credentials: 'secret'
          ,
            route: 'search'
            request:
              baseObject: SUFFIX
              scope: 'sub'
              derefAliases: 0
              sizeLimit: 0
              timeLimit: 10
              typesOnly: false
              filter: '(&(l=Seattle)(email=*@foo.com))'
              attributes: ''
          ]
          deferred.resolve()
        deferred.promise
