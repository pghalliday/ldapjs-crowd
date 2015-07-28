Q = require 'q'
chai = require 'chai'
chai.should()

crowd = require '../../mock/crowd'

PORT = 3000

describe 'crowd', ->
  before ->
    crowd.listen PORT

  after ->
    crowd.close()
