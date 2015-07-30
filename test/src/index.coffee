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
CROWD_URL = 'http://localhost:' + CROWD_PORT + '/crowd/'
APPLICATION_NAME = 'application'
APPLICATION_PASSWORD = 'password'

LDAP_PORT = 4000
LDAP_URL = 'ldap://localhost:' + LDAP_PORT
SUFFIX = 'o=example'
UID = 'uid'
INCORRECT_UID = 'hello'
BIND_DN = 'cn=root'
INCORRECT_BIND_DN = 'cn=hello'
PASSWORD = 'confidential'
INCORRECT_PASSWORD = 'hello'
BASE = 'ou=crowd'
INCORRECT_BASE = 'ou=hello'

INCORRECT_USER_NAME = 'hello'
INCORRECT_USER_PASSWORD = 'hello'

USER_NAME = 'fbloggs'
USER_PASSWORD = 'secret'
USER_FIRST_NAME = 'Fred'
USER_LAST_NAME = 'Bloggs'
USER_DISPLAY_NAME = 'Fred Bloggs'
USER_EMAIL = 'fred@bloggs.com'

USER_OBJECT = Object.create null
USER_OBJECT.name = USER_NAME
USER_OBJECT.active = true
USER_OBJECT['first-name'] = USER_FIRST_NAME
USER_OBJECT['last-name'] = USER_LAST_NAME
USER_OBJECT['display-name'] = USER_DISPLAY_NAME
USER_OBJECT.email = USER_EMAIL

INACTIVE_USER_NAME = 'jbloggs'
INACTIVE_USER_FIRST_NAME = 'Joe'
INACTIVE_USER_LAST_NAME = 'Bloggs'
INACTIVE_USER_DISPLAY_NAME = 'Joe Bloggs'
INACTIVE_USER_EMAIL = 'joe@bloggs.com'

INACTIVE_USER_OBJECT = Object.create null
INACTIVE_USER_OBJECT.name = INACTIVE_USER_NAME
INACTIVE_USER_OBJECT.active = false
INACTIVE_USER_OBJECT['first-name'] = INACTIVE_USER_FIRST_NAME
INACTIVE_USER_OBJECT['last-name'] = INACTIVE_USER_LAST_NAME
INACTIVE_USER_OBJECT['display-name'] = INACTIVE_USER_DISPLAY_NAME
INACTIVE_USER_OBJECT.email = INACTIVE_USER_EMAIL

describe 'ldapjs-crowd', ->
  ldapjsServer = undefined
  crowdServer = undefined
  backend = undefined

  beforeEach ->
    crowdServer = crowd.createServer
      applicationName: APPLICATION_NAME
      applicationPassword: APPLICATION_PASSWORD
      activeUser:
        username: USER_NAME
        userPassword: USER_PASSWORD
        firstName: USER_FIRST_NAME
        lastName: USER_LAST_NAME
        displayName: USER_DISPLAY_NAME
        email: USER_EMAIL
      inactiveUser:
        username: INACTIVE_USER_NAME
        firstName: INACTIVE_USER_FIRST_NAME
        lastName: INACTIVE_USER_LAST_NAME
        displayName: INACTIVE_USER_DISPLAY_NAME
        email: INACTIVE_USER_EMAIL
    ldapjsServer = ldapjs.createServer()
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
    ldapjsServer.bind SUFFIX, backend.bind()
    ldapjsServer.search SUFFIX, backend.search()
    Q()
      .then ->
        crowdServer.listen CROWD_PORT
      .then ->
        Q.ninvoke ldapjsServer, 'listen', LDAP_PORT

  afterEach ->
    deferred = Q.defer()
    ldapjsServer.on 'close', deferred.resolve
    ldapjsServer.close()
    deferred.promise
      .then ->
        crowdServer.close()
      .done()

  describe 'search', ->
    it 'should fail if not bound to the bindDn', ->
      client = ldapjs.createClient
        url: LDAP_URL
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
        .should.be.rejectedWith ldapjs.InsufficientAccessRightsError
        .then ->
          client.unbind()

  describe 'with gitlab client', ->
    it 'should authenticate a valid user', ->
      client = gitlab.createClient
        url: LDAP_URL
        uid: UID
        bindDn: BIND_DN + ',' + SUFFIX
        password: PASSWORD
        base: BASE + ',' + SUFFIX
      client.authenticate
        username: USER_NAME
        password: USER_PASSWORD
      .should.be.fulfilled

    it 'should fail on the first bind if the bindDn is incorrect', ->
      client = gitlab.createClient
        url: LDAP_URL
        uid: UID
        bindDn: INCORRECT_BIND_DN + ',' + SUFFIX
        password: PASSWORD
        base: BASE + ',' + SUFFIX
      client.authenticate
        username: USER_NAME
        password: USER_PASSWORD
      .should.be.rejectedWith /first bind failed/

    it 'should fail on the first bind if the password is incorrect', ->
      client = gitlab.createClient
        url: LDAP_URL
        uid: UID
        bindDn: BIND_DN + ',' + SUFFIX
        password: INCORRECT_PASSWORD
        base: BASE + ',' + SUFFIX
      client.authenticate
        username: USER_NAME
        password: USER_PASSWORD
      .should.be.rejectedWith /first bind failed/

    it 'should fail on the first search if the base is incorrect', ->
      client = gitlab.createClient
        url: LDAP_URL
        uid: UID
        bindDn: BIND_DN + ',' + SUFFIX
        password: PASSWORD
        base: INCORRECT_BASE + ',' + SUFFIX
      client.authenticate
        username: USER_NAME
        password: USER_PASSWORD
      .should.be.rejectedWith /first search failed/

    # coffeelint: disable=max_line_length
    it 'should fail on the first search with no match found if the uid is incorrect', ->
    # coffeelint: enable=max_line_length
      client = gitlab.createClient
        url: LDAP_URL
        uid: INCORRECT_UID
        bindDn: BIND_DN + ',' + SUFFIX
        password: PASSWORD
        base: BASE + ',' + SUFFIX
      client.authenticate
        username: USER_NAME
        password: USER_PASSWORD
      .should.be.rejectedWith /first search found no match/

    # coffeelint: disable=max_line_length
    it 'should fail on the first search with no match if no match is found for the user', ->
    # coffeelint: enable=max_line_length
      client = gitlab.createClient
        url: LDAP_URL
        uid: UID
        bindDn: BIND_DN + ',' + SUFFIX
        password: PASSWORD
        base: BASE + ',' + SUFFIX
      client.authenticate
        username: INCORRECT_USER_NAME
        password: USER_PASSWORD
      .should.be.rejectedWith /first search found no match/

    # coffeelint: disable=max_line_length
    it 'should fail on the first search with no match if the user is inactive', ->
    # coffeelint: enable=max_line_length
      client = gitlab.createClient
        url: LDAP_URL
        uid: UID
        bindDn: BIND_DN + ',' + SUFFIX
        password: PASSWORD
        base: BASE + ',' + SUFFIX
      client.authenticate
        username: INACTIVE_USER_NAME
        password: USER_PASSWORD
      .should.be.rejectedWith /first search found no match/
