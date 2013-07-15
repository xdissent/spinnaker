(function() {

  var WidgetListCtrl = function ($scope, Widget) {
    $scope.widgets = Widget.query();
  };

  WidgetListCtrl.$inject = ['$scope', 'Widget'];

  angular.module('widgetService', ['spinnaker'])
    .factory('Widget', ['spinnaker' , function (spinnaker) {
      return spinnaker('widget');
    }]);

  angular.module('app', ['widgetService'])
    .controller('WidgetListCtrl', WidgetListCtrl);

})();