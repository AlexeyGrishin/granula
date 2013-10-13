granulaCtor = (require('../granula/granula'))

angular.module('granula', [])

angular.module('granula').provider 'grService', ->

  granula = granulaCtor()

  argumentNamesByKey = {}

  removeOwnDirectives = (argName) ->
    foundAt = argName.search(/\|\s*grPluralize/i)
    if foundAt != -1
      argName.substring(0, foundAt)
    else
      argName

  #TODO: configurable
  mapArgumentByKey = (key) ->
    argumentNamesByKey[key] ||= [null]  #0st index
    (name) ->
      if name.match(/[0-9]+/)
        argumentNamesByKey[key][name]
      else
        argumentNamesByKey[key].push name if argumentNamesByKey[key].indexOf(name) == -1
        name


  angularInterpolator = (mapArgument = (name) -> name) ->
    begin: ->
    string: (ctx, text) -> text
    argument: (ctx, {argName}) ->
      "{{#{mapArgument(argName)}}}"
    pluralExpression: (ctx, {word, suffixes}, {argName}) ->
      "{{#{removeOwnDirectives(mapArgument(argName))} | grPluralize:'#{word}(#{suffixes.join(',')})'}}"
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
    originalLanguage: "en"
    setOriginalLanguage: (lang) ->
      @originalLanguage = lang
    setLanguage: (lang) ->
      return if lang is @language
      @language = lang
      $rootScope.$broadcast 'gr-lang-changed', lang

    save: (key, pattern, language = @originalLanguage) ->
      data = {}
      data[language] = {}
      data[language][key] = pattern
      granula.load data

    compile: (key, language = @language, skipIfEmpty = true) ->
      #TODO: uhly magic
      if argumentNamesByKey[key] is undefined and language isnt @originalLanguage
        @compile key, @originalLanguage, false
      try
        granula.compile(language, {key}).apply angularInterpolator(mapArgumentByKey(key))
      catch e
        throw e if not skipIfEmpty
        console.error(e)
        return ""   #continue working

    plural: (expression, value) ->
      compiled = peCache[expression] ? (=>
        peCache[expression] = granula.compile(@language, "#{expression}:1")
      )()
      compiled.apply pluralInterpolator(), value

#TODO: change order of args, {{'error(s)' | grPluralize:count}} looks more preferable
angular.module('granula').filter 'grPluralize', (grService) ->
  (input, pluralExpression) ->
    grService.plural(pluralExpression, input)


angular.module('granula').directive 'grLang', ($rootScope, grService, $interpolate)->
  compile: (el, attrs) ->
    grService.setOriginalLanguage attrs.grLangOfText if attrs.grLangOfText
    requireInterpolation = $interpolate(attrs.grLang, true)
    if requireInterpolation
      grService.setLanguage grService.originalLanguage
    else
      grService.setLanguage attrs.grLang
    (scope, el, attrs) ->
      attrs.$observe "grLang", (newVal) ->
        grService.setLanguage newVal


processDomText = (grService, $interpolate, interpolateKey, startKey, readTextFn, writeTextFn) ->
  pattern = readTextFn()
  if startKey
    grService.save startKey, pattern
    compiled = grService.compile(startKey)
    interpolateFn = $interpolate(compiled, true)
  if interpolateFn or interpolateKey
    writeTextFn('') # to prevent auto-binding made by angular.js

  link: (scope) ->
    outputFn = interpolateFn
    key = startKey

    onLanguageChanged = () ->
      outputFn = $interpolate(grService.compile(key))
      writeTextFn(outputFn(scope))

    onVariablesChanged = (text) ->
      return text if grService.language is grService.originalLanguage
      throw new Error("outputFn is undefined but it shall not be") if not outputFn
      writeTextFn(outputFn(scope))

    onKeyChanged = (newKey) ->
      return if key == newKey
      key = newKey
      onLanguageChanged()
    scope.$on "gr-lang-changed", -> onLanguageChanged()
    if interpolateFn
      scope.$watch interpolateFn, (text) -> onVariablesChanged(text)
    if interpolateKey
      scope.$watch interpolateKey, (newVal) ->
        onKeyChanged(newVal)
    onLanguageChanged() if startKey

    onKeyChanged: onKeyChanged





angular.module('granula').directive 'grAttrs', (grService, $interpolate, $parse) ->
  compile: (el, attrs) ->
    attrPairs = $parse(attrs.grAttrs)({})
    attrNames = Object.keys(attrPairs)
    linkFunctions = attrNames.map (key) ->
      val = attrPairs[key]
      if val == true
        val = el.attr(key)
      processDomText grService, $interpolate, null, val, (->el.attr(key)), (val) -> el.attr(key, val)
    (scope, el, attrs) ->
      keyListeners = linkFunctions.map (l) -> l.link(scope).onKeyChanged
      scope.$watch attrs.grAttrs,((newVal) ->
        for name, idx in attrNames
          keyListeners[idx](newVal[name]) if newVal[name] != true
      ), true



angular.module('granula').directive 'grKey', (grService, $interpolate) ->
  compile: (el, attrs) ->
    keyExpr = if attrs.grKey.length > 0 then attrs.grKey else el.text()
    interpolateKey = $interpolate(keyExpr, true) if attrs.grKey
    startKey = if interpolateKey then null else keyExpr
    {link} = processDomText(grService, $interpolate, interpolateKey, startKey, (-> el.text()), ((val) -> el.text(val)))
    (scope, el, attrs) ->
      link scope, attrs
