class SpinnakerProvider
  constructor: ->
    # All available socket.io message verb for subscription.
    @subscriptions = ['create', 'destroy', 'update']

    @instanceFilter = (model, params, subscribe, resource, msg) ->
      return false unless msg.model is model and msg.id is resource.id
      subscribe = subscribe arguments... if angular.isFunction subscribe
      return false unless angular.isArray subscribe and msg.verb in subscribe
      true

    @collectionFilter = (model, params, subscribe, resource, msg) ->
      return false unless msg.model is model
      subscribe = subscribe arguments... if angular.isFunction subscribe
      return false unless angular.isArray subscribe and msg.verb in subscribe
      true

    # Default actions from $resource plus subscriptions and `update`.
    @defaultActions =
      get: method: 'get', subscribe: ['update'] #, filter: @instanceFilter
      create: method: 'post'
      save: method: (params) -> if params?.id? then 'put' else 'post'
      destroy: method: 'delete'
      query:
        method: 'get'
        isArray: true
        subscribe: ['create', 'destroy', 'update']
        # filter: @collectionFilter
      # builds:
      #   url: '/dock/:id/builds'
      #   method:'GET'
      #   isArray: true
      #   resource: Build
      #   subscribe: ['create', 'destroy', 'update']
      #   filter: (model, resource, msg) ->

  setUrl: (@url) ->
  setMock: (@mock) ->
  setSubscriptions: (@subscriptions) ->
  setDefaultActions: (@defaultActions) ->

  $get: ($injector) ->
    inject = ['$window', '$rootScope', '$q']
    inject.push 'spinnakerMock' if @mock
    inject.push @service.bind @
    $injector.invoke inject

  service: ($window, $rootScope, $q, spinnakerMock) ->
    origin = @url ? $window.location?.origin ? 'http://localhost:1337'
    socket = spinnakerMock ? $window.io.connect origin

    socketRequest = ->
      deferred = $q.defer()
      socket[action.method] url, data, (data) -> deferred.resolve data
      deferred.promise

    (model, url="/#{model}/:id", actions) =>
      # Add custom actions from arguments.
      actions = angular.extend {}, @defaultActions, actions

      parseUrl = (url, params) ->
        url = url.replace ":#{k}", v for k, v of params when v?
        url = url.replace /\/?:\w+/g, ''
        url.replace /\/$/, ''

      request = (url, data={}, method='get') ->
        console.log arguments...
        deferred = $q.defer()
        socket[method] url, data, (data) -> deferred.resolve data
        deferred.promise

      createAction = (action) -> (a1, a2, a3, a4) ->
        console.log arguments...
        [params, data, success, error] = switch arguments.length
          when 4 then [a1, a2, a3, a4]
          when 3, 2
            if angular.isFunction a2
              if angular.isFunction a1
                [null, null, a1, a2]
              else
                [a1, null, a2, a3]
            else
              [a1, a2, a3, a4]
          when 1
            if angular.isFunction a1
              [null, null, null, a1]
            else
              [a1, null, null, null]
          else [null, null, null, null]

        instCall = @ instanceof Resource
        params ?= if instCall then @ else {}
        method = if angular.isFunction action.method then action.method params else action.method ? 'get'
        data ?= params if /^(POST|PUT|PATCH)$/i.test method
        console.log instCall, params, data, method
        request parseUrl(action.url ? url, params), data, method, (data) ->
          success data if success?
        , (err) ->
          error err if error?

      class Resource
        @[actionName] = createAction action for actionName, action of actions
        constructor: (data) ->
          copy data, @ if data?
          @[actionName] = createAction(action).bind @ for actionName, action of actions

angular.module('spinnaker', [])
  .provider 'spinnaker', SpinnakerProvider