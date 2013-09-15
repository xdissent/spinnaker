class SpinnakerProvider
  constructor: ->
    @socketTransport = ['$window', '$q', ($window, $q) =>

      buildUrl = (url, params) ->
        return url unless params?
        parts = []
        for key, value of params
          continue unless value?
          value = [].concat value
          for v in value
            v = angular.toJson v if angular.isObject v
            parts.push encodeUriQuery(key) + '=' + encodeUriQuery(v)
        return url unless parts.length > 0
        sep = if url.indexOf '?' is -1 then '?' else '&'
        "#{url}#{sep}#{parts.join '&'}"

      $window.io.SocketNamespace.prototype.patch ?= (url, data, cb) ->
        @request url, data, cb, 'patch'

      fallback = 'http://localhost:1337'
      origin = $window.location?.origin
      socketURL = @transportOptions.socketURL ? origin ? fallback
      socket = null

      request: (url, data={}, method, params) ->
        socket ?= $window.io.connect socketURL
        deferred = $q.defer()
        socket[method] buildUrl(url, params), data, (res) ->
          setTimeout -> # Make sure we're ok to apply root scope
            $rootScope.$apply ->
              return deferred.reject res if res.status?
              deferred.resolve res
            , 1
        deferred.promise
    ]

    @httpTransport = ['$http', ($http) ->
      request: (url, data, method, params) ->
        opts = url: url, data: data, method: method.toUpperCase(), params: params
        $http(opts).then (res) -> res.data
    ]

    @transport = @socketTransport
    @transportOptions = {}

    @defaultCache = ['$cacheFactory', ($cacheFactory) ->
      $cacheFactory 'spinnaker'
    ]

    @nullCache = [->
      get: ->
      put: ->
    ]

    @cache = @defaultCache

    @defaultOptions = [->
      single: false
      populate: []
      data: null
      params: null
      resource: null
      method: 'get'
    ]

    @defaultInterceptor = ['$q', ($q) ->
      success: (res) -> res
      error: (err) -> $q.reject err
    ]

  setTransport: (@transport) ->
  setTransportOptions: (@transportOptions) ->
  setCache: (@cache) ->
  setDefaultOptions: (@defaultOptions) ->
  setDefaultInterceptor: (@defaultInterceptor) ->
  
  $get: ($injector) -> $injector.invoke ['$injector', '$q', @service.bind @]

  service: ($injector, $q) ->
    interceptor = $injector.invoke @defaultInterceptor
    cache = $injector.invoke @cache
    defaultOptions = $injector.invoke @defaultOptions
    transport = $injector.invoke @transport

    failLater = (err) ->
      deferred = $q.defer()
      setTimeout (-> deferred.reject err), 1
      deferred.promise

    # Cache all GET request through transport
    request = (url, data, method='get', params={}) ->
      req = ->
        promise = transport.request url, data, method
        cache.put url, promise.then(null, -> cache.remove url) if method is 'get'
        promise
      $q.when(cache.get url if method is 'get').then (cached) ->
        if cached? then cached else req()
      , (err) -> req()

    # Convert data object or array to JSON patch payload
    dataToOps = (data, type) ->
      ops = []
      for d, index in [].concat data
        for k, v of d
          do (k, v) ->
            ops.push
              op: 'replace'
              path: "/#{type}/#{index}/#{k}"
              value: v
      ops

    # Convert data object or array to JSON-API document payload
    dataToCollection = (data, type) ->
      collection = {}
      collection[type] = [].concat data
      collection

    isSingleResourceOps = (ops) ->
      for op in ops
        path = op.path.replace /^(\/[^\/]+\/[^\/]+).*/, '$1'
        return false if previous? and path isnt previous
        previous = path
      true

    typeFromURL = (url, opts) ->
      if opts.single and opts.method isnt 'post'
        opts.type ?= url.split('/')[-2..][0]
      else
        opts.type ?= url.split('/')[-1..][0]

    spinnaker = (url, options={}) ->

      opts = angular.extend {}, defaultOptions, options
      opts.populate = [].concat opts.populate ? []
      resource = null

      if opts.method isnt 'delete'
        if opts.ops
          opts.method = 'patch'
          opts.data = opts.ops
          opts.single = isSingleResourceOps opts.ops
          opts.type ?= typeFromURL url, opts
          
        else if opts.data?
          opts.single = !angular.isArray opts.data
          if opts.method is 'patch'
            opts.type ?= typeFromURL url, opts
            opts.data = dataToOps opts.data, opts.type
          else
            opts.method = 'post'
            opts.type ?= typeFromURL url, opts
            opts.data = dataToCollection opts.data, opts.type

        else
          opts.type ?= typeFromURL url, opts

        resource = opts.resource ? if !opts.single
          new Collection opts.type
        else
          new Resource {}, opts.type

      promise = request(url, opts.data, opts.method, opts.params).then (res) ->
        
        # Cache compound documents always
        ignore = [opts.type, 'links', 'meta']
        for type, resources of res when type not in ignore
          for r in resources
            body = {}
            body[type] = [r]
            cache.put r.href, $q.when body

        return resource unless resource?

        if angular.isArray resource
          # Create a resource for each resource of type and push to collection
          resource.length = 0
          resource.push new Resource vals, opts.type for vals in res[opts.type]
        else
          # Update resource with values from response
          promise = resource.$promise
          resource.values res[opts.type][0]
          resource.$promise = promise

        # Delay resolution until populates are completed if there are any
        resource.$resolved = true unless opts.populate.length > 0
        resource
      , (err) ->
        resource.$resolved = true if resource?
        $q.reject err

      promise = promise.then interceptor.success, interceptor.error
      promise = promise.then (resource) ->
        return resource unless opts.populate.length > 0
        if angular.isArray resource
          $q.all(r.populate opts.populate for r in resource).then ->
            resource.$resolved = true
            resource
        else
          resource.populate(opts.populate).then ->
            resource.$resolved = true
            resource
      return promise if opts.resource? or opts.method is 'delete'
      resource.$promise = promise
      resource.$resolved = false
      resource

    Collection = (type) ->
      collection = new Array
      collection.$type = type
      collection

    class Resource
      constructor: (values={}, @$type) ->
        @$values = {}
        @values values
      values: (values) ->
        return @$values unless values?
        angular.copy values, @$values
        @[k] = v for k, v of values
      reload: -> spinnaker @href, resource: @, type: @$type
      save: ->
        opts = resource: @, type: @$type, method: 'patch', data: @dirties()
        spinnaker @href, opts
      isClean: -> @dirty().length is 0
      dirty: -> k for k, v of @$values when !angular.equals v, @[k]
      dirties: ->
        dirties = {}
        dirties[k] = @[k] for k in @dirty()
        dirties
      populate: (opts, extra) ->
        return $q.all(@populate o for o in opts) if angular.isArray opts
        opts = link: opts if angular.isString opts
        opts = angular.extend {}, opts, extra if extra?
        unless opts.link? and @links[opts.link]?
          return failLater new Error "Invalid link: #{opts.link}"
        return $q.when @[opts.link] if @[opts.link]?
        @[opts.link] = spinnaker @links[opts.link], opts
        @[opts.link].$promise ? @[opts.link]
      destroy: -> spinnaker @href, method: 'delete'

    spinnaker


angular.module('spinnaker', [])
  .provider 'spinnaker', SpinnakerProvider