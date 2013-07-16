# Karma configuration
# Generated on Sun Jul 14 2013 13:01:32 GMT-0500 (CDT)
path = require 'path'

module.exports = (karma) ->
  karma.configure

    # base path, that will be used to resolve all patterns, eg. files, exclude
    basePath: ''

    # frameworks to use
    frameworks: ['jasmine']

    # list of files / patterns to load in the browser
    files: [
      'components/angular-unstable/angular.js'
      'components/angular-resource-master/angular-resource.js'
      'components/angular-mocks/angular-mocks.js'
      'lib/spinnaker.js'
      'lib/spinnaker.mock.js'
      'test/unit/**/*Spec.coffee'
    ]

    # list of files to exclude
    exclude: [
      
    ]

    # test results reporter to use
    # possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['progress']

    # web server port
    port: 9876

    # cli runner port
    runnerPort: 9100

    # enable / disable colors in the output (reporters and logs)
    colors: true

    # level of logging
    # possible values: karma.LOG_DISABLE || karma.LOG_ERROR || karma.LOG_WARN || karma.LOG_INFO || karma.LOG_DEBUG
    logLevel: karma.LOG_DEBUG

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: true

    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari (only Mac)
    # - PhantomJS
    # - IE (only Windows)
    browsers: [
      'Chrome'
      # 'IE9 - Win7'
      # 'IE10 - Win7'
    ]

    # If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000

    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: false
