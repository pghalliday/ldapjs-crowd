Q = require 'q'
ldapjs = require 'ldapjs'

createEnum = (values) ->
  values.reduce(
    (enumeration, value, index) ->
      enumeration[value] = index
      enumeration
  ,
    Object.create null
  )

AUTHENTICATION_STAGES = createEnum [
  'FIRST_BIND'
  'FIRST_SEARCH'
  'SECOND_BIND'
  'THIRD_BIND'
  'SECOND_SEARCH'
]

class Apache
  constructor: (@params) ->
    @client = ldapjs.createClient
      url: @params.url

  authenticate: (params) =>
    state = AUTHENTICATION_STAGES.FIRST_BIND
    Q()
      .then =>
        Q.ninvoke @client, 'bind', @params.bindDn, @params.password
      .then =>
        state = AUTHENTICATION_STAGES.FIRST_SEARCH
        uidFilter = '(' + @params.uid + '=' + params.username + ')'
        Q.ninvoke @client, 'search', @params.base,
          scope: 'sub'
          sizeLimit: 1
          filter: '(&' + @params.filter + uidFilter + ')'
      .then (res) ->
        matches = []
        deferred = Q.defer()
        res.on 'searchEntry', matches.push.bind matches
        res.on 'end', ->
          if matches.length
            deferred.resolve()
          else
            deferred.reject 'no matches'
        res.on 'error', deferred.reject
        deferred.promise
      .then =>
        state = AUTHENTICATION_STAGES.SECOND_BIND
        Q.ninvoke(
          @client
          'bind'
          @params.uid + '=' + params.username + ',' + @params.base
          params.password
        )
      .then =>
        state = AUTHENTICATION_STAGES.THIRD_BIND
        Q.ninvoke @client, 'bind', @params.bindDn, @params.password
      .then =>
        state = AUTHENTICATION_STAGES.SECOND_SEARCH
        Q.ninvoke(
          @client
          'search'
          @params.uid + '=' + params.username + ',' + @params.base
          scope: 'base'
          filter: '(objectclass=*)'
        )
      .then (res) ->
        matches = []
        deferred = Q.defer()
        res.on 'searchEntry', matches.push.bind matches
        res.on 'end', ->
          if matches.length
            deferred.resolve()
          else
            deferred.reject 'no matches'
        res.on 'error', deferred.reject
        deferred.promise
      .catch (error) ->
        switch state
          when AUTHENTICATION_STAGES.FIRST_BIND
            throw new Error 'first bind failed'
          when AUTHENTICATION_STAGES.FIRST_SEARCH
            if error is 'no matches'
              throw new Error 'first search found no match'
            else
              throw new Error 'first search failed'
          when AUTHENTICATION_STAGES.SECOND_BIND
            throw new Error 'second bind failed'
          when AUTHENTICATION_STAGES.THIRD_BIND
            throw new Error 'third bind failed'
          when AUTHENTICATION_STAGES.SECOND_SEARCH
            if error is 'no matches'
              throw new Error 'second search found no match'
            else
              throw new Error 'second search failed'
      .finally =>
        Q.ninvoke @client, 'unbind'


module.exports.createClient = (ldapUrl) ->
  new Apache ldapUrl
