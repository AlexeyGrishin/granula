angular.module('granula').config(["grServiceProvider", function(grServiceProvider) {
  grServiceProvider.config({"onlyMarked":true,"textAsKey":"nokey","wordsLimitForKey":10,"replaceSpaces":false,"attrsToTranslate":["title","alt","placeholder"],"warnings":["subtags"]})
}])