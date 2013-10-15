module.exports = (config) ->
  config.set
    frameworks: ['jasmine']
    files: [
      "bower_components/angular/angular.js",
      "bower_components/angular-mocks/angular-mocks.js",
      "build/angularjs/granula.js",
      "test/angular/**/*.js"]
    browsers: ['PhantomJS']
    reporters: ['progress', 'junit', 'coverage']
    preprocessors:
      "build/angularjs/granula.js": ['coverage']
    junitReporter:
      outputFile: 'test-reports/client.xml',
    coverageReporter:
      type: 'html'
      dir: 'test-reports/'