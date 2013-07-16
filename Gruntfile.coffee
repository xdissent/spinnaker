module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-bower-task'
  grunt.loadNpmTasks 'grunt-karma'

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    clean:
      build: ['components', 'lib', 'test/app']
      testNpm: ['test/app/node_modules']

    concat:
      test:
        src: [
          'components/angular-unstable/angular.js'
          'components/angular-resource-master/angular-resource.js'
          'lib/spinnaker.js'
          'test/fixtures/app.js'
        ],
        dest: 'test/app/assets/linker/js/app.js'

    copy:
      test:
        files: [
          expand: true
          cwd: 'test/fixtures'
          src: ['index.ejs']
          dest: 'test/app/views/home'
        ]
      testNpm:
        files: [
          expand: true
          cwd: 'test/fixtures'
          src: ['package.json']
          dest: 'test/app'
        ]

    coffee:
      build:
        files:
          'lib/spinnaker.js': ['src/spinnaker.coffee']
          'lib/spinnaker.mock.js': ['src/socket-mock.coffee']

    uglify:
      build:
        src: 'lib/spinnaker.js'
        dest: 'lib/spinnaker.min.js'

    shell:
      testApp:
        command: 'node_modules/sails/bin/sails.js new test/app --linker'
      testNpm:
        command: 'npm install'
        options: execOptions: cwd: 'test/app'
      testModel:
        command: 'node_modules/sails/bin/sails.js generate widget'
        options: execOptions: cwd: 'test/app'
      testAppStart:
        command: 'node_modules/forever/bin/forever start app.js && sleep 5'
        options: execOptions: cwd: 'test/app'
      testAppStop:
        command: 'node_modules/forever/bin/forever stop app.js'
        options: execOptions: cwd: 'test/app'

    bower:
      install:
        options:
          copy: false

    karma:
      unit:
        configFile: './karma.conf.coffee'
        singleRun: true
      e2e:
        configFile: 'karma.e2e.conf.coffee'
        singleRun: true

  grunt.registerTask 'default', ['clean', 'bower:install', 'coffee', 'uglify']

  grunt.registerTask 'test:unit', [
    'clean'
    'bower:install'
    'coffee'
    'uglify'
    'karma:unit'
  ]

  grunt.registerTask 'test:e2e', [
    'clean'
    'bower:install'
    'coffee'
    'uglify'
    'shell:testApp'
    'concat:test'
    'copy:test'
    'copy:testNpm'
    'clean:testNpm'
    'shell:testNpm'
    'shell:testModel'
    'shell:testAppStart'
    'karma:e2e'
    'shell:testAppStop'
  ]

  grunt.registerTask 'test', ['test:unit', 'test:e2e']