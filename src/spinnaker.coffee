class SpinnakerProvider
  constructor: ->
    @defaultInterceptor = ['$q', ($q) ->
      success: (resource) -> resource
      error: (err) -> $q.reject err
    ]
    @defaultActions =
      get: method: 'get'
      create: method: 'post'
      save: method: (params) -> if params?.id? then 'put' else 'post'
      update: method: 'put'
      destroy: method: 'delete'
      query: method: 'get', isArray: true, filter: (msgData, params, data) ->
        for k, v of data
          return false unless angular.equals msgData[k], v
        true

  setUrl: (@url) ->
  setMock: (@mock) ->
  setDefaultActions: (@defaultActions) ->
  setDefaultInterceptor: (@defaultInterceptor) ->

  $get: ($injector) ->
    inject = ['$injector', '$window', '$rootScope', '$q']
    inject.push 'spinnakerMock' if @mock
    inject.push @service.bind @
    $injector.invoke inject

  service: ($injector, $window, $rootScope, $q, spinnakerMock) ->
    origin = @url ? $window.location?.origin ? 'http://localhost:1337'
    socket = spinnakerMock ? $window.io.connect origin
    interceptor = $injector.invoke @defaultInterceptor

    (model, url="/#{model}/:id", actions) =>
      # Add custom actions from arguments.
      actions = angular.extend {}, @defaultActions, actions
      
      for n, action of actions
        action.interceptor ?= {}
        action.interceptor.success ?= interceptor.success
        action.interceptor.error ?= interceptor.error

      parseUrl = (url, params) ->
        url = url.replace ":#{k}", v for k, v of params when v?
        url = url.replace /\/?:\w+/g, ''
        url.replace /\/$/, ''

      request = (url, data={}, method='get') ->
        deferred = $q.defer()
        socket[method] url, data, (data) ->
          # For some reason, GETs by id don't return an array, so test for that case
          if Object::toString.call(data) isnt "[object Array]"
            dataArray = [data]
            data = dataArray
          $rootScope.$apply ->
            return deferred.reject data if data.status?
            deferred.resolve data
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
        method = action.method ? 'get'
        method = action.method params if angular.isFunction action.method
        data ?= params if /^(GET|POST|PUT|PATCH|DELETE)$/i.test method
        resourceClass = action.resource ? Resource
        value = if action.isArray
          new ResourceCollection resourceClass, params, data, action.filter
        else
          if instCall then @ else new resourceClass data
        promise = request(parseUrl(action.url ? url, params), data, method).then (data) ->
          if data?
            if action.isArray
              value.length = 0
              value.push (new resourceClass d).subscribe() for d in data
            else
              promise = value.$promise
              angular.copy data, value
              value.$promise = promise
          value.$resolved = true
          value.subscribe()
          success value if success?
          value
        , (err) ->
          value.$resolved = true
          error err if error?
          $q.reject err
        promise = promise.then action.interceptor.success, action.interceptor.error
        return promise if instCall
        value.$promise = promise
        value.$resolved = false
        value

      subscribe = ->
        @unsubscribe()
        @_subscription = @_msgHandler.bind @
        socket.on 'message', @_subscription
        @

      unsubscribe = ->
        socket.removeListener 'message', @_subscription if @_subscription?
        @_subscription = null
        @

      ResourceCollection = (resourceClass, params, data, filter) ->
        filter ?= -> true
        collection = new Array
        collection.subscribe = subscribe.bind collection
        collection.unsubscribe = unsubscribe.bind collection
        collection._msgHandler = (msg) ->
          return false unless msg.model is resourceClass.model
          return false if msg.verb is 'create' and !filter msg.data, params, data
          $rootScope.$apply ->
            switch msg.verb
              when 'create'
                collection.push (new resourceClass msg.data).subscribe()
              when 'destroy'
                rem = []
                for r, i in collection when r?.id? and r.id is msg.id
                  rem.push i
                  r.unsubscribe()
                collection.splice i, 1 for i in rem
              when 'update'
                existing = (i for r, i in collection when r?.id? and r.id is msg.id)
                if filter msg.data, params, data
                  collection.push (new resourceClass msg.data).subscribe() if existing.length is 0
                else
                  collection.splice i, 1 for i in existing
        collection

      class Resource
        @model: model
        @[name] = createAction action for name, action of actions
        constructor: (data) -> angular.copy data, @ if data?
        subscribe: subscribe
        unsubscribe: unsubscribe
        _msgHandler: (msg) ->
          if msg.model is @constructor.model and msg.id is @id and msg.verb is 'update'
            $rootScope.$apply => angular.copy msg.data, @ if msg.data?

      for name, action of actions
        do (name, action) ->
          Resource.prototype[name] = ->
            result = Resource[name].bind(@) arguments...
            result.$promise ? result

      Resource

angular.module('spinnaker', [])
  .provider 'spinnaker', SpinnakerProvider
