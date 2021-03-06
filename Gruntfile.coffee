module.exports = (grunt) ->

  grunt.initConfig {
    karma:
      options:
        configFile: 'karma.coffee'
      run:
        options:
          singleRun: true
      background:
        options:
          background: true
    "jasmine_node":
      useCoffee: true
      jUnit:
        report: true
        savePath: "./test-reports/"
      specFolders: []
      projectRoot: "test/node"
      extensions: "coffee"
      spec: "Spec"
    "coffee":
      dev:
        expand: true
        cwd: "src"
        src: ["**/*.coffee"]
        dest: "src"
        ext: ".js"
      test:
        expand: true
        cwd: "test/angular"
        src: ["**/*.coffee"]
        dest: "test/angular"
        ext: ".js"
    "copy":
      "dev":
        files: [{
          expand: true
          cwd: 'src'
          src: ['granula/**/*.js','runner/**/*.js']
          dest: 'build/package/'
        },
        {
          dest: 'build/'
          src: ['package.json', 'README.md', 'Granulafile.sample', 'bin/granula*']
        }
        ]

    "browserify":
      dev:
        files:
          'build/angularjs/granula.js': ["src/granula/granula.js", "src/angular/granula.js"]
          'build/browser/granula.js': ["src/granula/granula.js", "src/browser/granula.js"]
    "watch":
      "runner":
        "files": ["src/runner/**/*.coffee", "test/node/runner/**/*.coffee"]
        "tasks": ["common-test"]
      "common":
        "files": ["src/granula/**/*.coffee", "test/node/granula/**/*.coffee"]
        "tasks": ["common-test", "angular-test"]
      "angular-only":
        "files": ["src/angular/**/*.coffee", "test/angular/**/*.coffee"]
        "tasks": ["angular-test"]

  }

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-karma'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.registerTask "build", ["coffee:dev", "browserify:dev", "copy:dev"]
  grunt.registerTask "common-test", ["build", "coffee:test", "jasmine_node:run"]
  grunt.registerTask "angular-test", ["build", "coffee:test", "karma:background:run"]
  grunt.registerTask "test", ["build", "coffee:test", "jasmine_node:run", "karma:run"]
  grunt.registerTask "default", ["build", "test"]
