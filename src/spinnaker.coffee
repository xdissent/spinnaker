class SpinnakerProvider
  constructor: ->
    # All available socket.io message verb for subscription.
    @subscriptions = ['create', 'destroy', 'update']

    # Default actions from $resource plus subscriptions and `update`.
    @defaultActions =
      get: method: 'GET', subscribe: ['update']
      save: method: 'POST'
      query:
        method:'GET'
        isArray: true
        subscribe: ['create', 'destroy', 'update']
      remove: method: 'DELETE'
      'delete': method: 'DELETE'
      update: method: 'PUT'

  setUrl: (@url) ->
  setMock: (@mock) ->
  setSubscriptions: (@subscriptions) ->
  setDefaultActions: (@defaultActions) ->

  $get: ($injector) ->
    inject = ['$window', '$rootScope', '$parse', '$q']
    inject.push 'spinnakerMock' if @mock
    inject.push @service.bind @
    $injector.invoke inject

  service: ($window, $rootScope, $parse, $q, spinnakerMock) ->
    origin = @url ? $window.location?.origin ? 'http://localhost:1337'
    socket = spinnakerMock ? $window.io.connect origin

    # Fake $http service hijacks $resource requests and send them over socket.io.
    $http = (httpConfig) ->
      deferred = $q.defer()
      url = httpConfig?.url ? '/'
      data = httpConfig?.data ? {}
      cb = (data) -> $rootScope.$apply -> deferred.resolve data: data
      method = httpConfig?.method?.toLowerCase() ? 'get'
      socket.request url, data, cb, method
      deferred.promise

    # Build a $resource factory using the fake $http service.
    $resource = angular.module('ngResource')
      ._invokeQueue[0][2]['1'][3] $http, $parse, $q

    # $resource factory wrapper to add resource interceptors.
    (name, url="/#{name}/:id", paramDefaults={id: '@id'}, actions) =>

      # The resource class, created by calling $resource() later.
      Resource = null

      # Add custom actions from arguments.
      actions = angular.extend {}, @defaultActions, actions

      # Resource response interceptor to subscribe to updates from Sails.
      interceptor = (actionName, action) => response: (response) =>

        # Bail unless there are subscriptions.
        return response.resource unless action.subscribe?

        # Subscribe to a single subscription, an array, or a function.
        subs = if action.subscribe in @subscriptions
          # It's a string, push it into an array.
          [].concat action.subscribe 
        else
          # It's an array or function.
          action.subscribe

        # Listen for messages and fire off subscriptions.
        socket.on 'message', (msg) ->

          # Call function subscription with raw message and bail.
          return subs response.resource, msg if angular.isFunction subs

          # Bail if the msg isn't for us.
          return null unless msg.model is name and msg.verb in subs

          # A callback to apply within the $rootScope.
          cb = null

          # Collection actions
          if action.isArray
            cb = switch msg.verb
              when 'create' then ->
                # Add a new resource to the collection.
                response.resource.push new Resource msg.data
              when 'destroy' then ->
                # Remove the destroyed resources from the collection.
                rem = []
                rem.push i for r, i in response.resource when r.id is msg.data.id
                response.resource.splice i, 1 for i in rem
              when 'update' then ->
                # Update the resources in the collection.
                angular.copy msg.data, r for r in response.resource when r.id is msg.data.id

          # Instance actions
          else
            cb = switch msg.verb
              when 'update' then ->
                # Update the resource directly.
                angular.copy msg.data, response.resource if msg.data.id is response.resource.id

          # Apply the callback within the $rootScope if one was found.
          $rootScope.$apply cb if cb?

        # Return the resource.
        response.resource

      # Add the interceptor to each action.
      a.interceptor = interceptor(n, a) for n, a of actions

      # Create and return the $resource class.
      Resource = $resource url, paramDefaults, actions

angular.module('spinnaker', ['ngResource'])
  .provider 'spinnaker', SpinnakerProvider