ldapjs = require 'ldapjs'

class CrowdBackend
  constructor: (@params) ->
  bind: (req, res, next) =>
    res.end()
    next()
  search: (req, res, next) =>
    res.end()
    next()
  add: (req, res, next) ->
    next new ldapjs.OtherError 'not implemented'
  modify: (req, res, next) ->
    next new ldapjs.OtherError 'not implemented'
  modifyDN: (req, res, next) ->
    next new ldapjs.OtherError 'not implemented'
  compare: (req, res, next) ->
    next new ldapjs.OtherError 'not implemented'
  del: (req, res, next) ->
    next new ldapjs.OtherError 'not implemented'

module.exports.createBackend = (params) ->
  new CrowdBackend params
