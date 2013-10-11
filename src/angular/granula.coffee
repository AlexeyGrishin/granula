granula = (require('../granula/granula'))

angular.module('granula', [])

angular.module('granula').provider 'grService', ->

  angularInterpolator = ->
    begin: ->
    string: (ctx, text) -> text
    argument: (ctx, argument) ->
      "{{#{argument.argument}}}"
    pluralExpression: (ctx, {word, suffixes}, argument) ->
      "{{#{argument.argument} | grPluralize:'#{word}(#{suffixes.join(',')})'}}"
    end: ->

  pluralInterpolator = ->
    string: -> ""
    argument: -> ""
    pluralExpression: (context, {fn}) ->
      fn(context.attrs[1])

  peCache = {}
  $get: ($rootScope) ->
    granula.load {en: {}}

    language: "en"
    setLanguage: (lang) ->
      return if lang is @language
      @language = lang
      $rootScope.$broadcast 'gr-lang-changed', lang

    save: (key, pattern, language = @language) ->
      data = {}
      data[language] = {}
      data[language][key] = pattern
      granula.load data

    compile: (key) ->
      granula.compile(@language, {key}).apply angularInterpolator()

    plural: (expression, value) ->
      compiled = peCache[expression] ? (=>
        peCache[expression] = granula.compile(@language, "{{1}}#{expression}")
      )()
      compiled.apply pluralInterpolator(), value

angular.module('granula').filter 'grPluralize', (grService) ->
  (input, pluralExpression) ->
    grService.plural(pluralExpression, input)

#TODO: test
angular.module('granula').directive 'grLang', ($rootScope, grService)->
  (scope, el, attrs) ->
    scope.$watch attrs.grLang, (newVal) ->
      grService.setLanguage newVal


angular.module('granula').directive 'grKey', (grService, $interpolate) ->
  compile: (el, attrs) ->
    pattern = el.text()
    key = attrs.grKey
    grService.save key, pattern
    compiled = grService.compile(key)
    console.log compiled
    interpolateFn = $interpolate(compiled, true)
    originalLang = grService.language
    if interpolateFn
      el.text('')     # to prevent auto-binding made by angular.js
    (scope, el) ->
      outputFn = interpolateFn
      translate = (text, scope, lang) ->
        return text if lang is originalLang
        outputFn(scope)

      scope.$on 'gr-lang-changed', ->
        outputFn = $interpolate(grService.compile(key))
        el.text(outputFn(scope))

      if interpolateFn
        scope.$watch (interpolateFn), (val) ->
          el.text(translate(val, scope, grService.language))
      else