(function() {
  var SpinnakerExpectation, SpinnakerMock, SpinnakerMockProvider;

  SpinnakerExpectation = (function() {
    function SpinnakerExpectation(method, url, data, headers) {
      this.method = method;
      this.url = url;
      this.data = data;
      this.headers = headers;
      this.responded = false;
    }

    SpinnakerExpectation.prototype.respond = function(data, headers) {
      if (data == null) {
        data = {};
      }
      if (headers == null) {
        headers = {};
      }
      return this.response = {
        data: data,
        headers: headers
      };
    };

    SpinnakerExpectation.prototype.matches = function(url, data, method) {
      if (this.responded) {
        return false;
      }
      if (("" + this.url).toLowerCase() !== ("" + url).toLowerCase()) {
        return false;
      }
      if (("" + this.method).toLowerCase() !== ("" + method).toLowerCase()) {
        return false;
      }
      if (!angular.toJson(this.data === angular.toJson(data))) {
        return false;
      }
      return true;
    };

    SpinnakerExpectation.prototype.toString = function() {
      return "" + this.url + ", " + this.method + ", " + (angular.toJson(this.data));
    };

    return SpinnakerExpectation;

  })();

  SpinnakerMock = (function() {
    function SpinnakerMock() {
      this.expectations = [];
      this.responses = [];
    }

    SpinnakerMock.prototype.on = function() {};

    SpinnakerMock.prototype.when = function() {
      return this.expect.apply(this, arguments);
    };

    SpinnakerMock.prototype.expect = function(method, url, data, headers) {
      var expectation;
      expectation = new SpinnakerExpectation(method, url, data, headers);
      this.expectations.push(expectation);
      return expectation;
    };

    SpinnakerMock.prototype.request = function(url, data, options, method) {
      var exp, expectations;
      expectations = (function() {
        var _i, _len, _ref, _results;
        _ref = this.expectations;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          exp = _ref[_i];
          if (exp.matches(url, data, method)) {
            _results.push(exp);
          }
        }
        return _results;
      }).call(this);
      if (!(expectations.length > 0)) {
        throw new Error("Unexpected request: " + url + ", " + method);
      }
      this.expectations = (function() {
        var _i, _len, _ref, _results;
        _ref = this.expectations;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          exp = _ref[_i];
          if (exp !== expectations[0]) {
            _results.push(exp);
          }
        }
        return _results;
      }).call(this);
      return this.responses.push(function() {
        if (options.success) {
          return options.success(expectations[0].response.data);
        }
      });
    };

    SpinnakerMock.prototype.flush = function() {
      var response, _i, _len, _ref;
      _ref = this.responses;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        response = _ref[_i];
        response();
      }
      return this.responses = [];
    };

    SpinnakerMock.prototype.verifyNoOutstandingExpectation = function() {
      if (this.expectations.length > 0) {
        throw new Error("Unsatisfied requests: " + (this.expectations.join(', ')));
      }
    };

    return SpinnakerMock;

  })();

  SpinnakerMockProvider = (function() {
    function SpinnakerMockProvider() {}

    SpinnakerMockProvider.prototype.$get = function() {
      return new SpinnakerMock;
    };

    return SpinnakerMockProvider;

  })();

  angular.module('spinnaker').provider('spinnakerMock', SpinnakerMockProvider).config([
    'spinnakerProvider', function(sp) {
      return sp.setMock(true);
    }
  ]);

}).call(this);
