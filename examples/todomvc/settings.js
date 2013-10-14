(function(cb) {
  cb({

  })
})(function(options) {
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = options;
  }
  else {
    this.angular.config(["grService", function(grServiceProvider) {
      grServiceProvider.setOptions(options)
    }])
  }

});