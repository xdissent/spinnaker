spinnaker
=========

[Sails](http://sailsjs.org) Resources Service for 
[AngularJS](http://angularjs.org)

Sails is realtime web framework for [Node](http://nodejs.org) built on 
[express](http://expressjs.com) and [socket.io](http://socket.io). AngularJS is
a super heroic Javascript framework that makes advanced UIs with automatic
data binding a snap. Spinnaker is an
[Angular Service](http://docs.angularjs.org/guide/dev_guide.services.understanding_services)
that talks to Sails, modeled after the official
[ngResource](http://docs.angularjs.org/api/ngResource.$resource) module. Rather
than communicating with HTTP requests, spinnaker sends and receives realtime
messages over socket.io. Thanks to Sails' realtime model updates and Angular's
[two-way data binding](http://docs.angularjs.org/guide/dev_guide.templates.databinding),
you can query Sails resources like with `$resource`, and the models will be
updated automatically when the data changes in the backend. If Sails is
configured to use the `redis` pubsub adapter, you AngularJS frontend can be
updated live from completely separate server processes.


Installation
------------

[Bower](http://bower.io) is the preferred installation method. Install bower
via npm:

```sh
$ sudo npm install bower -g
```


Install spinnaker via bower:

```sh
$ bower install spinnaker --save
```


Building from git is also easy:

```sh
$ git clone https://github.com/xdissent/spinnaker.git
$ cd spinnaker
$ npm install
```


The `lib` folder will contain the build artifacts.


Usage
-----

Install Sails 0.9 and create a new app with a model:

```sh
$ sudo npm install 'git+https://github.com/balderdashy/sails#development' -g
$ sails new example --linker
$ cd example
```


Install spinnaker and dependencies into the Sails linker folder:

```sh
$ echo '{"directory": "assets/js/components"}' > .bowerrc
$ bower install spinnaker --save
```


Generate a Sails model:

```sh
$ sails generate widget
```


Add spinnaker and its dependencies to your layout:

```ejs
<!-- example/views/layout.ejs -->

  <!-- ... snip ... -->

    <script src="/js/components/angular-unstable/angular.js"></script>
    <script src="/js/components/angular-resource-master/angular-resource.js"></script>
    <script src="/js/components/spinnaker/lib/spinnaker.js"></script>

    <!--SCRIPTS-->
    <!--SCRIPTS END-->
  </body>
</html>
```


Create an angular app at `example/assets/linker/js/app.js`:

```js
var WidgetListCtrl = function ($scope, Widget) {
  // Use the spinnaker service to query for all Widgets.
  $scope.widgets = Widget.query();

  // Create a widget.
  $scope.create = function () {
    var widget = new Widget({});
    widget.$save();
    // Or create via $http:
    // $http.post('/widget', {});
  };

  // Update a widget.
  $scope.update = function (widget) {
    widget.$update({});
    // Or update via $http:
    // $http.put('/widget/' + widget.id, widget);
  };

  // Delete a widget.
  $scope.destroy = function (widget) {
    widget.$remove();
    // Or destroy via $http:
    // $http['delete']('/widget/' + widget.id, widget);
  };
};

WidgetListCtrl.$inject = ['$scope', 'Widget'];

angular.module('widgetService', ['spinnaker'])
  .factory('Widget', ['spinnaker' , function (spinnaker) {
    return spinnaker('widget');
  }]);

angular.module('app', ['widgetService'])
  .controller('WidgetListCtrl', WidgetListCtrl);
```


Finally create a view for your app in `example/views/home/index.ejs`:

```ejs
<div ng-app="app" ng-controller="WidgetListCtrl">
  <button ng-click="create()">Create Widget</button>
  <ul>
    <li ng-repeat="widget in widgets">
      <pre>{{ widget }}</pre>
      <button ng-click="update(widget)">Update Widget</button>
      <button ng-click="destroy(widget)">Destroy Widget</button>
    </li>
  </ul>
</div>
```


Start the Sails server and visit `http://localhost:1337`:

```sh
$ sails lift
```

