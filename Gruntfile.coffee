module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    clean:
      build: ['bower_components', 'lib', 'test/app']

    concat:
      test:
        src: [
          'bower_components/angular-unstable/angular.js'
          'bower_components/angular-resource-master/angular-resource.js'
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

    coffee:
      build:
        files:
          'lib/spinnaker.js': ['src/socket.coffee', 'src/spinnaker.coffee']
          'lib/spinnaker.mock.js':
            ['src/socket-mock.coffee', 'src/spinnaker.coffee']

    uglify:
      build:
        src: 'lib/spinnaker.js'
        dest: 'lib/spinnaker.min.js'

    shell:
      testApp:
        command: 'node_modules/sails/bin/sails.js new --linker test/app'
      testModel:
        command: 'node_modules/sails/bin/sails.js generate widget'
        options: execOptions: cwd: 'test/app'
      testUnit:
        command: 'karma start karma.config.coffee --single-run'
      testE2e:
        command: 'karma start karma.e2e.config.coffee --single-run'

    bower: install: {}

  grunt.registerTask 'default', ['clean', 'bower:install', 'coffee', 'uglify']

  grunt.registerTask 'test', [
    'clean'
    'bower:install'
    'coffee'
    'uglify'
    'shell:testUnit'
    'shell:testApp'
    'concat:test'
    'copy:test'
    'shell:testModel'
    # 'shell:testE2e'
  ]