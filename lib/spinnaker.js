(function() {
  var SpinnakerProvider;

  SpinnakerProvider = (function() {
    function SpinnakerProvider() {
      this.defaultActions = {
        get: {
          method: 'get'
        },
        create: {
          method: 'post'
        },
        save: {
          method: function(params) {
            if ((params != null ? params.id : void 0) != null) {
              return 'put';
            } else {
              return 'post';
            }
          }
        },
        update: {
          method: 'put'
        },
        destroy: {
          method: 'delete'
        },
        query: {
          method: 'get',
          isArray: true,
          filter: function(msgData, params, data) {
            var k, v;
            for (k in data) {
              v = data[k];
              if (!angular.equals(msgData[k], v)) {
                return false;
              }
            }
            return true;
          }
        }
      };
    }

    SpinnakerProvider.prototype.setUrl = function(url) {
      this.url = url;
    };

    SpinnakerProvider.prototype.setMock = function(mock) {
      this.mock = mock;
    };

    SpinnakerProvider.prototype.setDefaultActions = function(defaultActions) {
      this.defaultActions = defaultActions;
    };

    SpinnakerProvider.prototype.$get = function($injector) {
      var inject;
      inject = ['$window', '$rootScope', '$q'];
      if (this.mock) {
        inject.push('spinnakerMock');
      }
      inject.push(this.service.bind(this));
      return $injector.invoke(inject);
    };

    SpinnakerProvider.prototype.service = function($window, $rootScope, $q, spinnakerMock) {
      var origin, socket, _ref, _ref1, _ref2,
        _this = this;
      origin = (_ref = (_ref1 = this.url) != null ? _ref1 : (_ref2 = $window.location) != null ? _ref2.origin : void 0) != null ? _ref : 'http://localhost:1337';
      socket = spinnakerMock != null ? spinnakerMock : $window.io.connect(origin);
      return function(model, url, actions) {
        var Resource, ResourceCollection, action, createAction, name, parseUrl, request, subscribe, unsubscribe, _fn;
        if (url == null) {
          url = "/" + model + "/:id";
        }
        actions = angular.extend({}, _this.defaultActions, actions);
        parseUrl = function(url, params) {
          var k, v;
          for (k in params) {
            v = params[k];
            if (v != null) {
              url = url.replace(":" + k, v);
            }
          }
          url = url.replace(/\/?:\w+/g, '');
          return url.replace(/\/$/, '');
        };
        request = function(url, data, method) {
          var deferred;
          if (data == null) {
            data = {};
          }
          if (method == null) {
            method = 'get';
          }
          deferred = $q.defer();
          socket[method](url, data, function(data) {
            return $rootScope.$apply(function() {
              return deferred.resolve(data);
            });
          });
          return deferred.promise;
        };
        createAction = function(action) {
          return function(a1, a2, a3, a4) {
            var data, error, instCall, method, params, promise, resourceClass, success, value, _ref3, _ref4, _ref5, _ref6;
            _ref3 = (function() {
              switch (arguments.length) {
                case 4:
                  return [a1, a2, a3, a4];
                case 3:
                case 2:
                  if (angular.isFunction(a2)) {
                    if (angular.isFunction(a1)) {
                      return [null, null, a1, a2];
                    } else {
                      return [a1, null, a2, a3];
                    }
                  } else {
                    return [a1, a2, a3, a4];
                  }
                  break;
                case 1:
                  if (angular.isFunction(a1)) {
                    return [null, null, a1, null];
                  } else {
                    return [a1, null, null, null];
                  }
                  break;
                default:
                  return [null, null, null, null];
              }
            }).apply(this, arguments), params = _ref3[0], data = _ref3[1], success = _ref3[2], error = _ref3[3];
            instCall = this instanceof Resource;
            if (params == null) {
              params = instCall ? this : {};
            }
            method = (_ref4 = action.method) != null ? _ref4 : 'get';
            if (angular.isFunction(action.method)) {
              method = action.method(params);
            }
            if (/^(POST|PUT|PATCH|DELETE)$/i.test(method)) {
              if (data == null) {
                data = params;
              }
            }
            resourceClass = (_ref5 = action.resource) != null ? _ref5 : Resource;
            value = action.isArray ? new ResourceCollection(resourceClass, params, data, action.filter) : instCall ? this : new resourceClass(data);
            promise = request(parseUrl((_ref6 = action.url) != null ? _ref6 : url, params), data, method).then(function(data) {
              var d, _i, _len;
              promise = value.$promise;
              if (data != null) {
                if (action.isArray) {
                  value.length = 0;
                  for (_i = 0, _len = data.length; _i < _len; _i++) {
                    d = data[_i];
                    value.push((new resourceClass(d)).subscribe());
                  }
                } else {
                  angular.copy(data, value);
                  value.$promise = promise;
                }
              }
              value.$resolved = true;
              value.subscribe();
              if (success != null) {
                return success(data);
              }
            }, function(err) {
              value.$resolved = true;
              if (error != null) {
                error(err);
              }
              return $q.reject(err);
            });
            if (instCall) {
              return promise;
            }
            value.$promise = promise;
            value.$resolved = false;
            return value;
          };
        };
        subscribe = function() {
          this.unsubscribe();
          this._subscription = this._msgHandler.bind(this);
          socket.on('message', this._subscription);
          return this;
        };
        unsubscribe = function() {
          if (this._subscription != null) {
            socket.removeListener('message', this._subscription);
          }
          this._subscription = null;
          return this;
        };
        ResourceCollection = function(resourceClass, params, data, filter) {
          var collection;
          if (filter == null) {
            filter = function() {
              return true;
            };
          }
          collection = new Array;
          collection.subscribe = subscribe.bind(collection);
          collection.unsubscribe = unsubscribe.bind(collection);
          collection._msgHandler = function(msg) {
            if (msg.model !== resourceClass.model) {
              return false;
            }
            if (msg.verb === 'create' && !filter(msg.data, params, data)) {
              return false;
            }
            return $rootScope.$apply(function() {
              var existing, i, r, rem, _i, _j, _k, _len, _len1, _len2, _results, _results1;
              switch (msg.verb) {
                case 'create':
                  return collection.push((new resourceClass(msg.data)).subscribe());
                case 'destroy':
                  rem = [];
                  for (i = _i = 0, _len = collection.length; _i < _len; i = ++_i) {
                    r = collection[i];
                    if (!(((r != null ? r.id : void 0) != null) && r.id === msg.id)) {
                      continue;
                    }
                    rem.push(i);
                    r.unsubscribe();
                  }
                  _results = [];
                  for (_j = 0, _len1 = rem.length; _j < _len1; _j++) {
                    i = rem[_j];
                    _results.push(collection.splice(i, 1));
                  }
                  return _results;
                  break;
                case 'update':
                  existing = (function() {
                    var _k, _len2, _results1;
                    _results1 = [];
                    for (i = _k = 0, _len2 = collection.length; _k < _len2; i = ++_k) {
                      r = collection[i];
                      if (((r != null ? r.id : void 0) != null) && r.id === msg.id) {
                        _results1.push(i);
                      }
                    }
                    return _results1;
                  })();
                  if (filter(msg.data, params, data)) {
                    if (existing.length === 0) {
                      return collection.push((new resourceClass(msg.data)).subscribe());
                    }
                  } else {
                    _results1 = [];
                    for (_k = 0, _len2 = existing.length; _k < _len2; _k++) {
                      i = existing[_k];
                      _results1.push(collection.splice(i, 1));
                    }
                    return _results1;
                  }
              }
            });
          };
          return collection;
        };
        Resource = (function() {
          var action, name;

          Resource.model = model;

          for (name in actions) {
            action = actions[name];
            Resource[name] = createAction(action);
          }

          function Resource(data) {
            if (data != null) {
              angular.copy(data, this);
            }
          }

          Resource.prototype.subscribe = subscribe;

          Resource.prototype.unsubscribe = unsubscribe;

          Resource.prototype._msgHandler = function(msg) {
            var _this = this;
            if (msg.model === this.constructor.model && msg.id === this.id && msg.verb === 'update') {
              return $rootScope.$apply(function() {
                if (msg.data != null) {
                  return angular.copy(msg.data, _this);
                }
              });
            }
          };

          return Resource;

        })();
        _fn = function(name, action) {
          return Resource.prototype[name] = function() {
            var result, _ref3;
            result = Resource[name].bind(this).apply(null, arguments);
            return (_ref3 = result.$promise) != null ? _ref3 : result;
          };
        };
        for (name in actions) {
          action = actions[name];
          _fn(name, action);
        }
        return Resource;
      };
    };

    return SpinnakerProvider;

  })();

  angular.module('spinnaker', []).provider('spinnaker', SpinnakerProvider);

}).call(this);
