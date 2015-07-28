class CrowdBackend
  constructor: (@params) ->
  add: (req, res, next) =>
    console.log 'add'
    console.log req
    console.log res
    res.end()
    next()
  modify: (req, res, next) =>
    console.log 'modify'
    console.log req
    console.log res
    res.end()
    next()
  modifyDN: (req, res, next) =>
    console.log 'modifyDN'
    console.log req
    console.log res
    res.end()
    next()
  bind: (req, res, next) =>
    console.log 'bind'
    console.log req
    console.log res
    res.end()
    next()
  compare: (req, res, next) =>
    console.log 'compare'
    console.log req
    console.log res
    res.end(false)
    next()
  del: (req, res, next) =>
    console.log 'del'
    console.log req
    console.log res
    res.end()
    next()
  search: (req, res, next) =>
    console.log 'search'
    console.log req
    console.log res
    res.end()
    next()

module.exports.createBackend = (params) ->
  new CrowdBackend params
