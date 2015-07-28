Q = require 'q'
ldapjs = require 'ldapjs'

class Gitlab
  constructor: (ldapUrl) ->
    @client = ldapjs.createClient
      url: ldapUrl
  bind: (dn, password) =>
    Q.ninvoke @client, 'bind', dn, password
  add: (dn, entry) =>
    Q.ninvoke @client, 'add', dn, entry
  modify: (dn, change) =>
    Q.ninvoke @client, 'modify', dn, new ldapjs.Change change
  modifyDN: (dn, newDn) =>
    Q.ninvoke @client, 'modifyDN', dn, newDn
  compare: (dn, attribute, value) =>
    Q.ninvoke @client, 'compare', dn, attribute, value
  del: (dn) =>
    Q.ninvoke @client, 'del', dn
  search: (dn, options) =>
    Q.ninvoke @client, 'search', dn, options
  unbind: =>
    Q.ninvoke @client, 'unbind'

module.exports.createClient = (ldapUrl) ->
  new Gitlab ldapUrl
