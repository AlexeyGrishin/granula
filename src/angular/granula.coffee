granula = (require('../granula/granula'))

angular.module('granula', [])

angular.module('granula').filter 'grTranslate', ->
  (input) -> granula.translate(input)