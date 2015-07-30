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

  describe '#failOnBind', ->
    describe 'with an offset of 0', ->
      beforeEach ->
        server.failOnBind 0

      it 'should force the server to fail on the first bind', ->
        Q()
          .then ->
            Q.ninvoke client, 'bind', SUFFIX, 'secret'
          .should.be.rejectedWith /forced fail/

    describe 'with an offset of 2', ->
      beforeEach ->
        server.failOnBind 2

      it 'should force the server to fail on the third bind', ->
        Q()
          .then ->
            Q.ninvoke client, 'bind', SUFFIX, 'secret'
          .then ->
            Q.ninvoke client, 'bind', SUFFIX, 'secret'
          .then ->
            Q.ninvoke client, 'bind', SUFFIX, 'secret'
          .should.be.rejectedWith /forced fail/
          .then ->
            server.calls.should.have.length 2

  describe '#failOnSearch', ->
    describe 'with an offset of 0', ->
      beforeEach ->
        server.failOnSearch 0

      it 'should force the server to fail on the first search', ->
        Q()
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .should.be.rejectedWith /forced fail/

    describe 'with an offset of 2', ->
      beforeEach ->
        server.failOnSearch 2

      it 'should force the server to fail on the third search', ->
        Q()
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .should.be.rejectedWith /forced fail/
          .then ->
            server.calls.should.have.length 2

  describe '#noMatchOnSearch', ->
    describe 'with an offset of 0', ->
      beforeEach ->
        server.noMatchOnSearch 0

      it 'should force the server to return no match on the first search', ->
        matches = []
        Q()
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'searchEntry', matches.push.bind matches
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .then ->
            matches.should.have.length 0

    describe 'with an offset of 2', ->
      beforeEach ->
        server.noMatchOnSearch 2

      it 'should force the server to return no match on the third search', ->
        matches = []
        Q()
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'searchEntry', matches.push.bind matches
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'searchEntry', matches.push.bind matches
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .then ->
            Q.ninvoke client, 'search', SUFFIX,
              filter: '(&(l=Seattle)(email=*@foo.com))'
              scope: 'sub'
          .then (res) ->
            deferred = Q.defer()
            res.on 'searchEntry', matches.push.bind matches
            res.on 'end', deferred.resolve
            res.on 'error', deferred.reject
            deferred.promise
          .then ->
            matches.should.have.length 2
