angular.module('granula').config(["grServiceProvider", function(grServiceProvider) {
  grServiceProvider.config({"textAsKey":"nokey","wordsLimitForKey":10,"replaceSpaces":false,"translateMe":"✍ "});
}]);