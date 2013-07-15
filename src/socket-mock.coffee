ng = angular.module 'spinnakerSocket', []

# The spinnaker socket service, which connects to the socket.io server.
ng.factory 'spinnakerSocket', ->

  # Dummy socket.io.
  io = connect: -> on: ->

  # Todo: config value for url.
  socket = io.connect()

  # Mocks for testing when socket.request doesn't exist (non-Sails env)

  class SpinnakerExpectation
    constructor: (@method, @url, @data, @headers) ->
      @responded = false
    respond: (data={}, headers={}) ->
      @response = data: data, headers: headers
    matches: (url, data, method) ->
      return false if @responded
      return false unless "#{@url}".toLowerCase() is "#{url}".toLowerCase()
      return false unless "#{@method}".toLowerCase() is "#{method}".toLowerCase()
      return false unless angular.toJson @data is angular.toJson data
      true
    toString: -> "#{@url}, #{@method}, #{angular.toJson @data}"

  socket.expectations = []

  socket.expect = (method, url, data, headers) ->
    expectation = new SpinnakerExpectation method, url, data, headers
    socket.expectations.push expectation
    expectation

  socket.when = -> socket.expect arguments...

  socket.responses = []
  socket.request = (url, data, options, method) ->
    expectations = (exp for exp in socket.expectations when exp.matches url, data, method)
    throw new Error "Unexpected request: #{url}, #{method}" unless expectations.length > 0
    socket.expectations = (exp for exp in socket.expectations when exp isnt expectations[0])
    socket.responses.push ->
      options.success expectations[0].response.data if options.success

  socket.flush = ->
    response() for response in socket.responses
    socket.responses = []

  socket.verifyNoOutstandingExpectation = ->
    if socket.expectations.length > 0
      throw new Error "Unsatisfied requests: #{socket.expectations.join ', '}"

  socket