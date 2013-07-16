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

class SpinnakerMock
  constructor: ->
    @expectations = []
    @responses = []

  on: ->

  when: -> @expect arguments...

  expect: (method, url, data, headers) ->
    expectation = new SpinnakerExpectation method, url, data, headers
    @expectations.push expectation
    expectation

  request: (url, data, options, method) ->
    expectations = (exp for exp in @expectations when exp.matches url, data, method)
    throw new Error "Unexpected request: #{url}, #{method}" unless expectations.length > 0
    @expectations = (exp for exp in @expectations when exp isnt expectations[0])
    @responses.push ->
      options.success expectations[0].response.data if options.success

  flush: ->
    response() for response in @responses
    @responses = []

  verifyNoOutstandingExpectation: ->
    if @expectations.length > 0
      throw new Error "Unsatisfied requests: #{@expectations.join ', '}"

class SpinnakerMockProvider
  $get: -> new SpinnakerMock

angular.module('spinnaker')
  .provider('spinnakerMock', SpinnakerMockProvider)
  .config ['spinnakerProvider', (sp) -> sp.setMock true]