(function() {

  var WidgetListCtrl = function ($http, $scope, Widget) {
    // Use the spinnaker service to query for all Widgets.
    $scope.widgets = Widget.query();

    // These methods trigger real HTTP requests to the REST URLs for Widget.
    // The changes resulting from each request are reflected in `$scope.widgets`
    // automatically through the spinnaker resource's subscription callbacks.
    // That means if something creates/updates/destroys Widget instances in the
    // backend, the scope and UI will be updated to reflect those changes
    // immediately. These raw HTTP requests simulate another process or request
    // manipulating the database out from under us.
    $scope.createHTTP = function () {
      $http.post('/widget', {});
    };
    $scope.updateHTTP = function (widget) {
      $http.put('/widget/' + widget.id, {});
    };
    $scope.destroyHTTP = function (widget) {
      $http['delete']('/widget/' + widget.id);
    };

    // These methods use the more familiar `$resource` interface to the CRUD
    // endpoints routed over socket.io.
    $scope.create = function () {
      var widget = new Widget({});
      widget.$save();
    };
    $scope.update = function (widget) {
      widget.$update({});
    };
    $scope.destroy = function (widget) {
      widget.$remove();
    };
  };

  WidgetListCtrl.$inject = ['$http', '$scope', 'Widget'];

  angular.module('widgetService', ['spinnaker'])
    .factory('Widget', ['spinnaker' , function (spinnaker) {
      return spinnaker('widget');
    }]);

  angular.module('app', ['widgetService'])
    .controller('WidgetListCtrl', WidgetListCtrl);

})();