Q = require 'q'
ldapjs = require 'ldapjs'

class Gitlab
  constructor: (@params) ->
    @client = ldapjs.createClient
      url: @params.url

  authenticate: (params) =>
    Q()
      .then =>
        Q.ninvoke @client, 'bind', @params.bindDn, @params.password
      .then =>
        Q.ninvoke @client, 'search', @params.base,
          scope: 'sub'
          sizeLimit: 1
          filter: '(' + @params.uid + '=' + params.username + ')'
      .then (res) =>
        deferred = Q.defer()
        res.on 'end', deferred.resolve
        deferred.promise
      .then =>
        Q.ninvoke(
          @client
          'bind'
          @params.uid + '=' + params.username + ',' + @params.base
          params.password
        )
      .then =>
        Q.ninvoke @client, 'bind', @params.bindDn, @params.password
      .then =>
        Q.ninvoke(
          @client
          'search'
          @params.uid + '=' + params.username + ',' + @params.base
          scope: 'base'
          filter: '(objectclass=*)'
        )
      .then (res) =>
        deferred = Q.defer()
        res.on 'end', deferred.resolve
        deferred.promise
      .then =>
        Q.ninvoke @client, 'unbind'

module.exports.createClient = (ldapUrl) ->
  new Gitlab ldapUrl
