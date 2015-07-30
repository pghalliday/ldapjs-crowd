Q = require 'q'
supertest = require 'supertest'
chai = require 'chai'
chai.should()

crowd = require '../../mock/crowd'

PORT = 3000
URL = 'http://localhost:' + PORT
APPLICATION_NAME = 'application'
APPLICATION_PASSWORD = 'password'
INCORRECT_APPLICATION_PASSWORD = 'hello'

INCORRECT_USER_NAME = 'hello'

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

INACTIVE_USER_ERROR =
  reason: 'INACTIVE_ACCOUNT'
  message: 'Account is inactive'

INVALID_CREDENTIALS_ERROR =
  reason: 'INVALID_USER_AUTHENTICATION'
  message: 'Username or password is invalid'

describe 'crowd', ->
  server = undefined
  request = undefined

  before ->
    server = crowd.createServer
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
    request = supertest URL
    server.listen PORT

  after ->
    server.close()

  it 'should authenticate requests', ->
    deferred = Q.defer()
    request
      .get('/')
      .auth(APPLICATION_NAME, INCORRECT_APPLICATION_PASSWORD)
      .expect(401)
      .end (err, res) ->
        if err
          deferred.reject err
        else
          deferred.resolve()
    deferred.promise.should.be.fulfilled

  describe 'GET /crowd/rest/usermanagement/1/user', ->
    describe 'with an active user', ->
      it 'should return the user', ->
        deferred = Q.defer()
        request
          .get('/crowd/rest/usermanagement/1/user')
          .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
          .query
            username: USER_NAME
          .expect(200)
          .expect('Content-Type', 'application/json')
          .end (err, res) ->
            if err
              deferred.reject err
            else
              deferred.resolve res.body
        deferred.promise.should.eventually.become USER_OBJECT

    describe 'with an inactive user', ->
      it 'should return the user', ->
        deferred = Q.defer()
        request
          .get('/crowd/rest/usermanagement/1/user')
          .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
          .query
            username: INACTIVE_USER_NAME
          .expect(200)
          .expect('Content-Type', 'application/json')
          .end (err, res) ->
            if err
              deferred.reject err
            else
              deferred.resolve res.body
        deferred.promise.should.eventually.become INACTIVE_USER_OBJECT

    describe 'with an invalid user', ->
      it 'should return 404', ->
        deferred = Q.defer()
        request
          .get('/crowd/rest/usermanagement/1/user')
          .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
          .query
            username: INCORRECT_USER_NAME
          .expect(404)
          .end (err, res) ->
            if err
              deferred.reject err
            else
              deferred.resolve()
        deferred.promise.should.be.fulfilled

    describe '#failOnUser', ->
      it 'should force a user query to 404 after offset queries', ->
        server.failOnUser 1
        Q()
          .then ->
            deferred = Q.defer()
            request
              .get('/crowd/rest/usermanagement/1/user')
              .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
              .query
                username: USER_NAME
              .expect(200)
              .expect('Content-Type', 'application/json')
              .end (err, res) ->
                if err
                  deferred.reject err
                else
                  deferred.resolve res.body
            deferred.promise.should.eventually.become(USER_OBJECT)
          .then ->
            deferred = Q.defer()
            request
              .get('/crowd/rest/usermanagement/1/user')
              .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
              .query
                username: USER_NAME
              .expect(404)
              .end (err, res) ->
                if err
                  deferred.reject err
                else
                  deferred.resolve res.body
            deferred.promise.should.be.fulfilled


  describe 'POST /crowd/rest/usermanagement/1/authentication', ->
    describe 'with a valid user and password', ->
      it 'should return the user', ->
        deferred = Q.defer()
        request
          .post('/crowd/rest/usermanagement/1/authentication')
          .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
          .query
            username: USER_NAME
          .send
            value: USER_PASSWORD
          .expect(200)
          .expect('Content-Type', 'application/json')
          .end (err, res) ->
            if err
              deferred.reject err
            else
              deferred.resolve res.body
        deferred.promise.should.eventually.become USER_OBJECT

    describe 'with an inactive user', ->
      it 'should return an inactive user error', ->
        deferred = Q.defer()
        request
          .post('/crowd/rest/usermanagement/1/authentication')
          .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
          .query
            username: INACTIVE_USER_NAME
          .send
            value: USER_PASSWORD
          .expect(200)
          .expect('Content-Type', 'application/json')
          .end (err, res) ->
            if err
              deferred.reject err
            else
              deferred.resolve res.body
        deferred.promise.should.eventually.become INACTIVE_USER_ERROR

    describe 'with an unknown user', ->
      it 'should return a 404', ->
        deferred = Q.defer()
        request
          .post('/crowd/rest/usermanagement/1/authentication')
          .auth(APPLICATION_NAME, APPLICATION_PASSWORD)
          .query
            username: INCORRECT_USER_NAME
          .send
            value: USER_PASSWORD
          .expect(404)
          .end (err, res) ->
            if err
              deferred.reject err
            else
              deferred.resolve res.body
        deferred.promise.should.be.fulfilled
