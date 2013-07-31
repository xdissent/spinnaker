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
      create: method: 'post', subscribe: ['update']
      save: subscribe: ['update'], method: (params) -> if params?.id? then 'put' else 'post'
      update: method: 'put'
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

    (model, url="/#{model}/:id", actions) =>
      # Add custom actions from arguments.
      actions = angular.extend {}, @defaultActions, actions

      parseUrl = (url, params) ->
        url = url.replace ":#{k}", v for k, v of params when v?
        url = url.replace /\/?:\w+/g, ''
        url.replace /\/$/, ''

      request = (url, data={}, method='get') ->
        deferred = $q.defer()
        socket[method] url, data, (data) ->
          $rootScope.$apply -> deferred.resolve data
        deferred.promise

      createAction = (action) -> (a1, a2, a3, a4) ->
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
              [null, null, a1, null]
            else
              [a1, null, null, null]
          else [null, null, null, null]

        instCall = @ instanceof Resource
        params ?= if instCall then @ else {}
        method = if angular.isFunction action.method then action.method params else action.method ? 'get'
        data ?= params if /^(POST|PUT|PATCH|DELETE)$/i.test method
        resource = action.resource ? Resource
        value = if action.isArray then [] else if instCall then @ else new resource data
        promise = request(parseUrl(action.url ? url, params), data, method).then (data) ->
          promise = value.$promise
          if data?
            if action.isArray
              value.length = 0
              value.push new resource d for d in data
            else
              angular.copy data, value
              value.$promise = promise
          value.$resolved = true
          success data if success?
          value
        , (err) ->
          value.$resolved = true
          error err if error?
          $q.reject err
        return promise if instCall
        value.$promise = promise
        value.$resolved = false
        value

      class Resource
        @[name] = createAction action for name, action of actions
        constructor: (data) -> angular.copy data, @ if data?

      for name, action of actions
        do (name, action) ->
          Resource.prototype[name] = ->
            result = Resource[name].bind(@) arguments...
            result.$promise ? result

      Resource

angular.module('spinnaker', [])
  .provider 'spinnaker', SpinnakerProvider