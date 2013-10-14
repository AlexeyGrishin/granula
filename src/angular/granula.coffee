granulaCtor = (require('../granula/granula'))
keys = require('../granula/keys')

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

    wrap = (language, dataToWrap) ->
      data = {}
      data[language] = dataToWrap ? {}
      data

    language: "en"
    originalLanguage: "en"

    isOriginal: ->
      @language == @originalLanguage

    registerOriginal: ->
      @register @originalLanguage
      @registerOriginal = ->

    setOriginalLanguage: (lang) ->
      @originalLanguage = lang
      @registerOriginal()

    setLanguage: (lang) ->
      return if lang is @language
      @language = lang
      $rootScope.$broadcast 'gr-lang-changed', lang

    register: (language) ->
      throw new Error("language shall be defined!") if not language
      granula.load wrap(language)

    load: (values, language) ->
      throw new Error("language shall be defined!") if not language
      granula.load wrap(language, values)

    save: (key, pattern, language = @originalLanguage) ->
      data = wrap(language)
      data[language][key] = pattern
      granula.load data

    compile: (key, language = @language, skipIfEmpty = true) ->
      @registerOriginal()
      #TODO: uhly magic
      if argumentNamesByKey[key] is undefined and language isnt @originalLanguage
        @compile key, @originalLanguage, false
      try
        granula.compile(language, {key}).apply angularInterpolator(mapArgumentByKey(key))
      catch e
        throw e if not skipIfEmpty
        console.error(e.message, e)
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


angular.module('granula').directive 'grLang', ($rootScope, grService, $interpolate, $http)->
  byLangLoaders = {}
  compileScript = (el, attrs) ->
    langName = attrs.grLang
    throw new Error("gr-lang for script element shall have value - name of language") if (langName ? "").length == 0
    grService.register(langName)
    if attrs.src
      byLangLoaders[langName] = {
        loaded: false
        load: (cb) ->
          $http(method: "GET", url: attrs.src).success( (data)=>
            @loaded = true
            cb(data)
          ).error(->
            #TODO: revert somehow
            console.error("Cannot load #{attrs.src} for language #{langName}")
          )
      }
      #TODO: make async. Langage change = (send event1, switch state to 'loading', load data async, send event2, switch state back)
      byLangLoaders[langName].load (data) ->
        grService.load data, langName
    else
      byLangLoaders[langName] = loaded: true
      try
        grService.load JSON.parse(el.text()), langName
      catch e
        throw new Error("Cannot parse json for language '#{langName}'", e)

    (scope) ->
      onLanguageChanged = ->
        loader = byLangLoaders[grService.language]
        if loader?.loaded == false
          loader.load (data) ->
            console.log "Loaded data for #{langName}"
            grService.load data, langName
            scope.$apply() if not scope.$$phase
        else if grService.isOriginal() or loader?.loaded == true
          #do nothing - it is already here, right on page
        else
          throw new Error("Cannot switch to language #{grService.language} - there is no data for it")
      scope.$on 'gr-lang-changed', onLanguageChanged
      onLanguageChanged()


  compileOther = (el, attrs) ->
    grService.setOriginalLanguage attrs.grLangOfText if attrs.grLangOfText
    requireInterpolation = $interpolate(attrs.grLang, true)
    if requireInterpolation
      grService.setLanguage grService.originalLanguage
    else
      grService.setLanguage attrs.grLang
    (scope, el, attrs) ->
      attrs.$observe "grLang", (newVal) ->
        grService.setLanguage newVal if newVal.length

  compile: (el, attrs) ->
    if el[0].tagName == 'SCRIPT'
      compileScript(el, attrs)
    else
      compileOther(el, attrs)



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
      return writeTextFn(text) if grService.language is grService.originalLanguage
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
    attrNames = attrs.grAttrs.split(",")
    linkFunctions = attrNames.map (attrName) ->
      attrWithKeyValue = "grKey#{attrName[0].toUpperCase() + attrName.substring(1)}"
      #TODO: use keys.textToKey options
      keyExpr = attrs[attrWithKeyValue] ? keys.textToKey(el.attr(attrName))
      interpolateKey = $interpolate(keyExpr, true) if attrs[attrWithKeyValue]
      startKey = if interpolateKey then null else keyExpr
      processDomText grService, $interpolate, interpolateKey, startKey, (->el.attr(attrName)), (val) -> el.attr(attrName, val)
    (scope, el, attrs) ->
      keyListeners = linkFunctions.map (l) -> l.link(scope).onKeyChanged



angular.module('granula').directive 'grKey', (grService, $interpolate) ->
  compile: (el, attrs) ->
    #TODO: use keys.textToKey options
    keyExpr = if attrs.grKey.length > 0 then attrs.grKey else keys.textToKey(el.text())
    interpolateKey = $interpolate(keyExpr, true) if attrs.grKey
    startKey = if interpolateKey then null else keyExpr
    {link} = processDomText(grService, $interpolate, interpolateKey, startKey, (-> el.text()), ((val) -> el.text(val)))
    (scope, el, attrs) ->
      link scope, attrs
