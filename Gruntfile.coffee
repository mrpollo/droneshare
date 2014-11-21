path = require 'path'

# Build configurations
module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)
  require('time-grunt')(grunt)

  appConfig = {
    app: require('./bower.json').appPath || 'app'
    dist: 'dist'
  }

  grunt.initConfig
    settings:
      distDirectory: 'dist'
      srcDirectory: 'src'
      tempDirectory: '.temp'
      testDirectory: 'test'
      testPort: 9001
      devPort: 9099

    sauceconnect:
      options:
        keepAlive: true
        accessKey: process.env.SAUCE_ACCESS_KEY
        username: process.env.SAUCE_USERNAME
      test: {}
      dev: {}

    # Gets dependent components from bower
    # see bower.json file
    bower:
      install:
        options:
          verbose: true
          cleanTargetDir: true
          copy: true
          layout: (type, component) ->
            path.join type
          targetDir: 'bower_components'
      uninstall:
        options:
          cleanBowerDir: true
          copy: false
          install: false

    # Deletes dist and .temp directories
    # The .temp directory is used during the build process
    # The dist directory contains the artifacts of the build
    # These directories should be deleted before subsequent builds
    # These directories are not committed to source control
    clean:
      working: [
        '<%= settings.tempDirectory %>'
        '<%= settings.distDirectory %>'
      ]
      # Used for those that desire plain old JavaScript
      jslove: [
        '**/*.coffee'
        '!**/.temp/**'
        '!**/bower_components/**'
        '!**/node_modules/**'
      ]

    # Compiles CoffeeScript (.coffee) files to JavaScript (.js)
    coffee:
      app:
        files: [
          cwd: '<%= settings.tempDirectory %>'
          src: '**/*.coffee'
          dest: '<%= settings.tempDirectory %>'
          expand: true
          ext: '.js'
        ]
        options:
          sourceMap: true
      # Used for those that desire plain old JavaScript
      jslove:
        files: [
          cwd: ''
          src: '<%= clean.jslove %>'
          dest: ''
          expand: true
          ext: '.js'
        ]

    # Lints CoffeeScript files
    coffeelint:
      app:
        files: [
          cwd: ''
          src: [
            'src/**/*.coffee'
            '!src/scripts/libs/**'
          ]
        ]
        options:
          indentation:
            value: 2
          max_line_length:
            level: 'ignore'
          no_tabs:
            level: 'ignore'

    # Sets up a web server
    connect:
      options:
        port: '<%= settings.devPort %>' # Use 0 for dynamic
        base: '<%= settings.distDirectory %>'
        hostname: 'localhost'
        livereload: 35729
        middleware: require './middleware'
      app:
        options:
          open: true
      test:
        options:
          port: 9001

    # Copies directories and files from one location to another
    copy:
      app:
        files: [
          cwd: '<%= settings.srcDirectory %>'
          src: '**'
          dest: '<%= settings.tempDirectory %>'
          expand: true
        ,
          cwd: 'bower_components'
          src: '**'
          dest: '<%= settings.tempDirectory %>'
          expand: true
        ,
          cwd: 'WEB-INF'
          src: 'app.yaml'
          dest: '<%= settings.tempDirectory %>/'
          expand: true
        ]
      dev:
        cwd: '<%= settings.tempDirectory %>'
        src: '**'
        dest: '<%= settings.distDirectory %>'
        expand: true
      prod:
        files: [
          cwd: '<%= settings.tempDirectory %>'
          src: [
            '**/*.{eot,svg,ttf,woff}'
            '**/*.{gif,jpeg,jpg,png,svg,webp}'
            'index.html'
            'scripts/ie.min.*.js'
            'scripts/scripts.min.*.js'
            'styles/styles.min.*.css'
          ]
          dest: '<%= settings.distDirectory %>'
          expand: true
        ]

    # Renames files based on their hashed content
    # When the files contents change, the hash value changes
    # Used as a cache buster, ensuring browsers load the correct static resources
    #
    # glyphicons-halflings.png -> glyphicons-halflings.6c8829cc6f.png
    # scripts.min.js -> scripts.min.6c355e03ee.js
    hash:
      images: '.temp/**/*.{gif,jpeg,jpg,png,svg,webp}'
      scripts:
        cwd: '.temp/scripts'
        src: [
          'ie.min.js'
          'scripts.min.js'
        ]
        expand: true
      styles: '.temp/styles/styles.min.css'

    # Compresses png files
    imagemin:
      images:
        files: [
          cwd: '<%= settings.tempDirectory %>'
          src: '**/*.{gif,jpeg,jpg,png}'
          dest: '<%= settings.tempDirectory %>'
          expand: true
        ]
        options:
          optimizationLevel: 7

    # Runs unit tests using karma
    karma:
      unit:
        options:
          browsers: [
            'PhantomJS'
          ]
          captureTimeout: 5000
          colors: true
          frameworks: [
            'jasmine'
          ]
          keepalive: false
          logLevel: 'INFO'
          port: 9876
          reporters: [
            'dots'
            'progress'
          ]
          preprocessors: {
            '**/*.coffee': 'coffee'
          }
          files: [
            {pattern: 'dist/scripts/libs/angular.min.js', watched: false, served: true, included: true}
            {pattern: 'dist/scripts/libs/angular*.min.js', watched: false, served: true, included: true}
            {pattern: 'test/fixtures/*.json', watched: false, served: true, included: false}
            {pattern: 'bower_components/scripts/libs/angular-mocks.js', watched: false, served: true, included: true}
            {pattern: 'dist/scripts/libs/mapbox.js', watched: false, served: true, included: true}
            {pattern: 'dist/scripts/libs/jquery.js', watched: false, served: true, included: true}
            {pattern: 'bower_components/scripts/libs/jasmine-jquery.js', watched: false, served: true, included: true}
            {pattern: 'dist/**/*.js', watched: false, served: true, included: true}
            {pattern: 'test/units/**/*.coffee', watched: true, served: true, included: true}
          ]
          runnerPort: 9100
          singleRun: !grunt.option('watch')

    protractor_webdriver:
      test_e2e:
        options:
          path: './node_modules/protractor/bin/'
          command: 'webdriver-manager start'

    protractor:
      options:
        keepAlive: true
        noColor: false
      dev:
        configFile: 'protractor.conf.coffee'
        options:
          debug: grunt.option('debug-protractor')
      test_e2e:
        options:
          configFile: 'protractor.saucelabs.conf.coffee'

    # Compile LESS (.less) files to CSS (.css)
    less:
      app:
        files:
          '.temp/styles/styles.css': '.temp/styles/styles.less'

    # Minifies index.html
    # Extra white space and comments will be removed
    # Content within <pre /> tags will be left unchanged
    # IE conditional comments will be left unchanged
    # Reduces file size by over 14%
    minifyHtml:
      prod:
        src: '.temp/index.html'
        ext: '.html'
        expand: true

    # Creates a file to push views directly into the $templateCache
    # This will produce a file with the following content
    #
    # angular.module('app').run(['$templateCache', function ($templateCache) {
    #   $templateCache.put('/views/directives/tab.html', '<div class="tab-pane" ng-class="{active: selected}" ng-transclude></div>');
    #   $templateCache.put('/views/directives/tabs.html', '<div class="tabbable"> <ul class="nav nav-tabs"> <li ng-repeat="tab in tabs" ng-class="{active:tab.selected}"> <a href="http://localhost:3005/scripts/views.js" ng-click="select(tab)">{{tab.caption}}</a> </li> </ul> <div class="tab-content" ng-transclude></div> </div>');
    #   $templateCache.put('/views/people.html', '<ul ng-hide="!people.length"> <li class="row" ng-repeat="person in people | orderBy:\'name\'"> <a ng-href="#/people/{{person.id}}" ng-bind="person.name"></a> </li> </ul>');
    #   $templateCache.put('/views/repos.html', '<ul ng-hide="!repos.length"> <li ng-repeat="repo in repos | orderBy:\'pushed_at\':true"> <a ng-href="{{repo.url}}" ng-bind="repo.name" target="_blank"></a> <div ng-bind="repo.description"></div> </li> </ul>');
    #   $templateCache.put('/views/tweets.html', '<ul ng-hide="!tweets.length"> <li class="row" ng-repeat="tweet in tweets"> <div class="span1 thumbnail"> <img ng-src="{{tweet.profile_image_url}}"/> </div> <div class="span6"> <div> <b ng-bind="tweet.from_user_name"></b> <a ng-href="https://twitter.com/{{tweet.from_user}}" ng-bind="tweet.from_user | twitterfy" target="_blank"></a> </div> <div ng-bind="tweet.text"></div> </div> </li> </ul>');
    # }]);
    #
    # This file is then included in the output automatically
    # AngularJS will use it instead of going to the file system for the views, saving requests
    # Notice that the view content is actually minified.  :)
    ngTemplateCache:
      views:
        files:
          '.temp/scripts/views.js': '.temp/**/*.html'
        options:
          trim: '<%= settings.tempDirectory %>'

    prompt:
      jslove:
        options:
          questions: [
            {
              config: 'coffee.jslove.compile'
              type: 'input'
              message: 'Are you sure you wish to convert all CoffeeScript (.coffee) files to JavaScript (.js)?' + '\n' + 'This cannot be undone.'.red + ': (y/N)'
              default: false
              filter: (input) ->
                confirmed = /^y(es)?/i.test input

                if not confirmed
                  grunt.fatal 'exiting jslove'

                return confirmed
            }
          ]

    # RequireJS optimizer configuration for both scripts and styles
    # This configuration is only used in the 'prod' build
    # The optimizer will scan the main file, walk the dependency tree, and write the output in dependent sequence to a single file
    # Since RequireJS is not being used outside of the main file or for dependency resolution (this is handled by AngularJS), RequireJS is not needed for final output and is excluded
    # RequireJS is still used for the 'dev' build
    # The main file is used only to establish the proper loading sequence
    requirejs:
      scripts:
        options:
          baseUrl: '.temp/scripts'
          findNestedDependencies: true
          logLevel: 0
          mainConfigFile: '.temp/scripts/main.js'
          name: 'main'
          # Exclude main from the final output to avoid the dependency on RequireJS at runtime
          onBuildWrite: (moduleName, path, contents) ->
            modulesToExclude = ['main']
            shouldExcludeModule = modulesToExclude.indexOf(moduleName) >= 0

            return '' if shouldExcludeModule

            contents
          optimize: 'uglify2'
          out: '.temp/scripts/scripts.min.js'
          preserveLicenseComments: false
          skipModuleInsertion: true
          uglify:
            # Let uglifier replace variables to further reduce file size
            no_mangle: false
          useStrict: true
          wrap:
            start: '(function(){\'use strict\';'
            end: '}).call(this);'
      styles:
        options:
          baseUrl: '.temp/styles/'
          cssIn: '.temp/styles/styles.css'
          logLevel: 0
          optimizeCss: 'standard'
          out: '.temp/styles/styles.min.css'

    # Creates main file for RequireJS
    shimmer:
      dev:
        cwd: '.temp/scripts'
        src: [
          '**/*.{coffee,js}'
          '!libs/html5shiv-printshiv.{coffee,js}'
          '!libs/json3.min.{coffee,js}'
          '!libs/require.{coffee,js}'
          '!libs/jasmine-jquery.js'
        ]
        order: [
          'libs/spin.js'
          'libs/ladda.js'
          'custom/atmosphere.js'
          'libs/jquery.js'
          'libs/jquery.flot.js'
          'libs/jquery.flot.time.js'
          'libs/angular-file-upload-shim.min.js'
          'libs/angular.min.js'
          'libs/mapbox.js'
          'NGAPP':
            'ngProgressLite': 'libs/ngprogress-lite.js'
            'ngAnimate': 'libs/angular-animate.min.js'
            'ngRoute': 'libs/angular-route.min.js'
            'leaflet-directive': 'custom/angular-leaflet-directive.js'
            'ngAtmosphere': 'custom/angular-atmosphere.js'
            'angulartics': 'libs/angulartics.min.js'
            'angulartics.google.analytics': 'libs/angulartics-ga.min.js'
            'ui.bootstrap': 'libs/ui-bootstrap-tpls-0.11.0.min.js'
            'angular-flot': 'libs/angular-flot.js'
            'ngSocial': 'libs/angular-social.js'
            'angularFileUpload': 'libs/angular-file-upload.min.js'
            'infinite-scroll': 'libs/ng-infinite-scroll.js'
            'ngLaddaBootstrap': 'libs/ng-ladda-bootstrap.js'
            'highcharts-ng': 'libs/highcharts-ng.js'
        ]
        require: 'NGBOOTSTRAP'
      prod:
        cwd: '<%= shimmer.dev.cwd %>'
        src: [
          '**/*.{coffee,js}'
          '!libs/angular.{coffee,js}'
          '!libs/angular-animate.{coffee,js}'
          '!libs/angular-mocks.{coffee,js}'
          '!libs/angular-route.{coffee,js}'
          '!libs/html5shiv-printshiv.{coffee,js}'
          '!libs/json3.min.{coffee,js}'
          '!libs/require.{coffee,js}'
          '!libs/jasmine-jquery.js'
        ]
        order: [
          'libs/spin.js'
          'libs/ladda.js'
          'custom/atmosphere.js'
          'libs/jquery.js'
          'libs/jquery.flot.js'
          'libs/jquery.flot.time.js'
          'libs/angular-file-upload-shim.min.js'
          'libs/angular.min.js'
          'libs/mapbox.js'
          'NGAPP':
            'ngProgressLite': 'libs/ngprogress-lite.js'
            'ngAnimate': 'libs/angular-animate.min.js'
            'ngRoute': 'libs/angular-route.min.js'
            'leaflet-directive': 'custom/angular-leaflet-directive.js'
            'ngAtmosphere': 'custom/angular-atmosphere.js'
            'angulartics': 'libs/angulartics.min.js',
            'angulartics.google.analytics': 'libs/angulartics-ga.min.js',
            'ui.bootstrap': 'libs/ui-bootstrap-tpls-0.11.0.min.js',
            'angular-flot': 'libs/angular-flot.js',
            'ngSocial': 'libs/angular-social.js',
            'angularFileUpload': 'libs/angular-file-upload.min.js'
            'infinite-scroll': 'libs/ng-infinite-scroll.js'
            'ngLaddaBootstrap': 'libs/ng-ladda-bootstrap.js'
            'highcharts-ng': 'libs/highcharts-ng.js'
        ]
        require: '<%= shimmer.dev.require %>'
      test:
        cwd: '.temp/scripts'
        src: [
          '!libs/angular-mocks.{coffee,js}'
          '**/*.{coffee,js}'
          '!libs/html5shiv-printshiv.{coffee,js}'
          '!libs/json3.min.{coffee,js}'
          '!libs/require.{coffee,js}'
          '!libs/jasmine-jquery.js'
        ]
        order: [
          'libs/spin.js'
          'libs/ladda.js'
          'custom/atmosphere.js'
          'libs/jquery.js'
          'libs/jquery.flot.js'
          'libs/jquery.flot.time.js'
          'libs/angular-file-upload-shim.min.js'
          'libs/angular.min.js'
          'libs/mapbox.js'
          'NGAPP':
            'ngMockE2E': 'libs/angular-mocks.js'
            'ngProgressLite': 'libs/ngprogress-lite.js'
            'ngAnimate': 'libs/angular-animate.min.js'
            'ngRoute': 'libs/angular-route.min.js'
            'leaflet-directive': 'custom/angular-leaflet-directive.js'
            'ngAtmosphere': 'custom/angular-atmosphere.js'
            'angulartics': 'libs/angulartics.min.js'
            'angulartics.google.analytics': 'libs/angulartics-ga.min.js'
            'ui.bootstrap': 'libs/ui-bootstrap-tpls-0.11.0.min.js'
            'angular-flot': 'libs/angular-flot.js'
            'ngSocial': 'libs/angular-social.js'
            'angularFileUpload': 'libs/angular-file-upload.min.js'
            'infinite-scroll': 'libs/ng-infinite-scroll.js'
            'ngLaddaBootstrap': 'libs/ng-ladda-bootstrap.js'
            'highcharts-ng': 'libs/highcharts-ng.js'
        ]
        require: 'NGBOOTSTRAP'

    # Compiles underscore expressions
    #
    # The example below demonstrates the use of the environment configuration setting
    # In 'prod' build the hashed file of the concatenated and minified scripts is referened
    # In environments other than 'prod' the individual files are used and loaded with RequireJS
    #
    # <% if (config.environment === 'prod') { %>
    #   <script src="<%= config.getHashedFile('.temp/scripts/scripts.min.js', {trim: '.temp'}) %>"></script>
    # <% } else { %>
    #   <script data-main="/scripts/main.js" src="/scripts/libs/require.js"></script>
    # <% } %>
    template:
      indexDev:
        files:
          '.temp/index.html': '.temp/index.html'
      index:
        files: '<%= template.indexDev.files %>'
        environment: 'prod'

    # Concatenates and minifies JavaScript files
    uglify:
      scripts:
        files:
          '.temp/scripts/ie.min.js': [
            '.temp/scripts/libs/json3.js'
            '.temp/scripts/libs/html5shiv-printshiv.js'
          ]

    # Run tasks when monitored files change
    watch:
      basic:
        files: [
          'src/fonts/**'
          'src/images/**'
          'src/scripts/**/*.js'
          'src/styles/**/*.css'
          'src/**/*.html'
        ]
        tasks: [
          'coffeelint'
          'copy:app'
          'copy:dev'
          'karma'
        ]
        options:
          livereload: true
          nospawn: true
      coffee:
        files: 'src/scripts/**/*.coffee'
        tasks: [
          'clean:working'
          'coffeelint'
          'copy:app'
          'shimmer:dev'
          'coffee:app'
          'copy:dev'
          'karma'
        ]
        options:
          livereload: true
          nospawn: true
      less:
        files: 'src/styles/**/*.less'
        tasks: [
          'copy:app'
          'less'
          'copy:dev'
        ]
        options:
          livereload: true
          nospawn: true
      html:
        files: 'src/views/**/*.html'
        tasks: [
          'copy:app'
          'ngTemplateCache'
          'shimmer:dev'
          'template:indexDev'
          'copy:dev'
        ]
      spaHtml:
        files: 'src/index.html'
        tasks: [
          'copy:app'
          'template:indexDev'
          'copy:dev'
          'karma'
        ]
        options:
          livereload: true
          nospawn: true
      test:
        files: 'test/**/*.*'
        tasks: [
          'karma'
        ]
      # Used to keep the web server alive
      none:
        files: 'none'
        options:
          livereload: true

  # ensure only tasks are executed for the changed file
  # without this, the tasks for all files matching the original pattern are executed
  grunt.event.on 'watch', (action, filepath, key) ->
    file = filepath.substr(4) # trim "src/" from the beginning.  I don't like what I'm doing here, need a better way of handling paths.
    dirname = path.dirname file
    ext = path.extname file
    basename = path.basename file, ext

    grunt.config ['copy', 'app'],
      cwd: 'src/'
      src: file
      dest: '.temp/'
      expand: true

    copyDevConfig = grunt.config ['copy', 'dev']
    copyDevConfig.src = file

    if key is 'coffee'
      # delete associated temp file prior to performing remaining tasks
      # without doing so, shimmer may fail
      grunt.config ['clean', 'working'], [
        path.join('.temp', dirname, "#{basename}.{coffee,js,js.map}")
      ]

      copyDevConfig.src = [
        path.join(dirname, "#{basename}.{coffee,js,js.map}")
        'scripts/main.{coffee,js,js.map}'
      ]

      coffeeConfig = grunt.config ['coffee', 'app', 'files']
      coffeeConfig.src = file
      coffeeLintConfig = grunt.config ['coffeelint', 'app', 'files']
      coffeeLintConfig = filepath

      grunt.config ['coffee', 'app', 'files'], coffeeConfig
      grunt.config ['coffeelint', 'app', 'files'], coffeeLintConfig

    if key is 'less'
      copyDevConfig.src = [
        path.join(dirname, "#{basename}.{less,css}")
        path.join(dirname, 'styles.css')
      ]

    grunt.config ['copy', 'dev'], copyDevConfig

  # Compiles the app with non-optimized build settings
  # Places the build artifacts in the dist directory
  # Enter the following command at the command line to execute this build task:
  # grunt build
  grunt.registerTask 'build', [
    'clean:working'
    'coffeelint'
    'copy:app'
    'ngTemplateCache'
    'shimmer:dev'
    'coffee:app'
    'less'
    'template:indexDev'
    'copy:dev'
  ]

  # Compiles the app with non-optimized build settings
  # Places the build artifacts in the dist directory
  # Opens the app in the default browser
  # Watches for file changes, and compiles and reloads the web browser upon change
  # Enter the following command at the command line to execute this build task:
  # grunt or grunt default
  grunt.registerTask 'default', [
    'build'
    'connect'
    'watch'
  ]

  # Identical to the default build task
  # Compiles the app with non-optimized build settings
  # Places the build artifacts in the dist directory
  # Opens the app in the default browser
  # Watches for file changes, and compiles and reloads the web browser upon change
  # Enter the following command at the command line to execute this build task:
  # grunt dev
  grunt.registerTask 'dev', [
    'default'
  ]

  # Compiles the app with optimized build settings
  # Places the build artifacts in the dist directory
  # Enter the following command at the command line to execute this build task:
  # grunt prod
  grunt.registerTask 'prod', [
    'clean:working'
    'coffeelint'
    'copy:app'
    'ngTemplateCache'
    'shimmer:prod'
    'coffee:app'
    'imagemin'
    'hash:images'
    'less'
    'requirejs'
    'uglify'
    'hash:scripts'
    'hash:styles'
    'template:index'
    'minifyHtml'
    'copy:prod'
  ]

  # Opens the app in the default browser
  # Build artifacts must be in the dist directory via a prior grunt build, grunt, grunt dev, or grunt prod
  # Enter the following command at the command line to execute this build task:
  # grunt server
  grunt.registerTask 'server', [
    'connect'
    'watch:none'
  ]

  # Compiles the app with non-optimized build settings
  # Places the build artifacts in the dist directory
  # Runs unit tests via karma
  # Enter the following command at the command line to execute this build task:
  # grunt test
  grunt.registerTask 'test', [
    'build'
    'karma'
    'integration-tests:dev'
  ]

  # Compiles all CoffeeScript files in the project to JavaScript then deletes all CoffeeScript files
  # Used for those that desire plain old JavaScript
  # Enter the following command at the command line to execute this build task:
  # grunt jslove
  grunt.registerTask 'jslove', [
    'prompt:jslove'
    'coffee:jslove'
    'clean:jslove'
  ]

  grunt.registerTask 'integration-tests', [
    'build'
    'connect:test'
    'sauceconnect:test'
    'protractor:test_e2e'
  ]

  grunt.registerTask 'integration-tests:dev', [
    'clean:working'
    'coffeelint'
    'copy:app'
    'ngTemplateCache'
    'shimmer:test'
    'coffee:app'
    'less'
    'template:indexDev'
    'copy:dev'

    'connect:test'
    'protractor_webdriver'
    'protractor:dev'
  ]
