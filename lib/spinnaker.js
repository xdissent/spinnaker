(function() {
  var SpinnakerProvider,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  SpinnakerProvider = (function() {
    function SpinnakerProvider() {
      this.subscriptions = ['create', 'destroy', 'update'];
      this.defaultActions = {
        get: {
          method: 'GET',
          subscribe: ['update']
        },
        save: {
          method: 'POST'
        },
        query: {
          method: 'GET',
          isArray: true,
          subscribe: ['create', 'destroy', 'update']
        },
        remove: {
          method: 'DELETE'
        },
        'delete': {
          method: 'DELETE'
        },
        update: {
          method: 'PUT'
        }
      };
    }

    SpinnakerProvider.prototype.setUrl = function(url) {
      this.url = url;
    };

    SpinnakerProvider.prototype.setMock = function(mock) {
      this.mock = mock;
    };

    SpinnakerProvider.prototype.setSubscriptions = function(subscriptions) {
      this.subscriptions = subscriptions;
    };

    SpinnakerProvider.prototype.setDefaultActions = function(defaultActions) {
      this.defaultActions = defaultActions;
    };

    SpinnakerProvider.prototype.$get = function($injector) {
      var inject;
      inject = ['$window', '$rootScope', '$parse', '$q'];
      if (this.mock) {
        inject.push('spinnakerMock');
      }
      inject.push(this.service.bind(this));
      return $injector.invoke(inject);
    };

    SpinnakerProvider.prototype.service = function($window, $rootScope, $parse, $q, spinnakerMock) {
      var $http, $resource, origin, socket, _ref, _ref1, _ref2,
        _this = this;
      origin = (_ref = (_ref1 = this.url) != null ? _ref1 : (_ref2 = $window.location) != null ? _ref2.origin : void 0) != null ? _ref : 'http://localhost:1337';
      socket = spinnakerMock != null ? spinnakerMock : $window.io.connect(origin);
      $http = function(httpConfig) {
        var cb, data, deferred, method, url, _ref3, _ref4, _ref5, _ref6;
        deferred = $q.defer();
        url = (_ref3 = httpConfig != null ? httpConfig.url : void 0) != null ? _ref3 : '/';
        data = (_ref4 = httpConfig != null ? httpConfig.data : void 0) != null ? _ref4 : {};
        cb = function(data) {
          return $rootScope.$apply(function() {
            return deferred.resolve({
              data: data
            });
          });
        };
        method = (_ref5 = httpConfig != null ? (_ref6 = httpConfig.method) != null ? _ref6.toLowerCase() : void 0 : void 0) != null ? _ref5 : 'get';
        socket.request(url, data, cb, method);
        return deferred.promise;
      };
      $resource = angular.module('ngResource')._invokeQueue[0][2]['1'][3]($http, $parse, $q);
      return function(name, url, paramDefaults, actions) {
        var Resource, a, interceptor, n;
        if (url == null) {
          url = "/" + name + "/:id";
        }
        if (paramDefaults == null) {
          paramDefaults = {
            id: '@id'
          };
        }
        Resource = null;
        actions = angular.extend({}, _this.defaultActions, actions);
        interceptor = function(actionName, action) {
          return {
            response: function(response) {
              var subs, _ref3;
              if (action.subscribe == null) {
                return response.resource;
              }
              subs = (_ref3 = action.subscribe, __indexOf.call(_this.subscriptions, _ref3) >= 0) ? [].concat(action.subscribe) : action.subscribe;
              socket.on('message', function(msg) {
                var cb, _ref4;
                if (angular.isFunction(subs)) {
                  return subs(response.resource, msg);
                }
                if (!(msg.model === name && (_ref4 = msg.verb, __indexOf.call(subs, _ref4) >= 0))) {
                  return null;
                }
                cb = null;
                if (action.isArray) {
                  cb = (function() {
                    switch (msg.verb) {
                      case 'create':
                        return function() {
                          return response.resource.push(new Resource(msg.data));
                        };
                      case 'destroy':
                        return function() {
                          var i, r, rem, _i, _j, _len, _len1, _ref5, _results;
                          rem = [];
                          _ref5 = response.resource;
                          for (i = _i = 0, _len = _ref5.length; _i < _len; i = ++_i) {
                            r = _ref5[i];
                            if (r.id === msg.id) {
                              rem.push(i);
                            }
                          }
                          _results = [];
                          for (_j = 0, _len1 = rem.length; _j < _len1; _j++) {
                            i = rem[_j];
                            _results.push(response.resource.splice(i, 1));
                          }
                          return _results;
                        };
                      case 'update':
                        return function() {
                          var r, _i, _len, _ref5, _results;
                          _ref5 = response.resource;
                          _results = [];
                          for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
                            r = _ref5[_i];
                            if (r.id === msg.data.id) {
                              _results.push(angular.copy(msg.data, r));
                            }
                          }
                          return _results;
                        };
                    }
                  })();
                } else {
                  cb = (function() {
                    switch (msg.verb) {
                      case 'update':
                        return function() {
                          if (msg.data.id === response.resource.id) {
                            return angular.copy(msg.data, response.resource);
                          }
                        };
                    }
                  })();
                }
                if (cb != null) {
                  return $rootScope.$apply(cb);
                }
              });
              return response.resource;
            }
          };
        };
        for (n in actions) {
          a = actions[n];
          a.interceptor = interceptor(n, a);
        }
        return Resource = $resource(url, paramDefaults, actions);
      };
    };

    return SpinnakerProvider;

  })();

  angular.module('spinnaker', ['ngResource']).provider('spinnaker', SpinnakerProvider);

}).call(this);
