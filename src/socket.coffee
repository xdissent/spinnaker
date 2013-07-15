ng = angular.module 'spinnakerSocket', []

# The spinnaker socket service, which connects to the socket.io server.
ng.factory 'spinnakerSocket', ->

  # Todo: config value for url.
  io.connect 'http://localhost:1337'