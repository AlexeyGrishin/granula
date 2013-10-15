granulaCtor = (require('../granula/granula'))
keys = require('../granula/keys')

angular.module('granula', [])

#TODO: copy-paste from runner.coffee, move to separate fie
defaultOptions =
  textAsKey: "nokey",
  wordsLimitForKey: 10,
  replaceSpaces: false,
  generateSettingsFile: "settings.js",


angular.module('granula').provider 'grService', ->

  granula = granulaCtor()
  argumentNamesByKey = {}
  options = defaultOptions

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
      #TODO: do I really need it? why cannot I interpolate my own way?
      "{{#{removeOwnDirectives(mapArgument(argName))} | grPluralize:'#{word}(#{suffixes.join(',')})'}}"
    end: ->

  pluralInterpolator = ->
    string: -> ""
    argument: -> ""
    pluralExpression: (context, {fn}) ->
      fn(context.attrs[1])

  peCache = {}
  asyncLoaders = {}

  config: (opts) ->
    angular.extend options, defaultOptions, opts

  $get: ($rootScope) ->
    wrap = (language, dataToWrap) ->
      data = {}
      data[language] = dataToWrap ? {}
      data

    # Currently shown language
    # Use @setLanguage method to change it, or 'gr-lang' directive
    language: "en"

    # Language of the text on page
    # Use @setOriginalLanguage to change it, or 'gr-lang' directive
    originalLanguage: "en"

    # Generates phrase key for text with specified gr-key attribute depending on settings
    # Settings could be changed using grServiceProvider.config
    toKey: (attribute, text) ->
      keys.toKey(attribute, text, options)

    # Returns true if current language is original language
    isOriginal: ->
      @language == @originalLanguage

    _registerOriginal: ->
      @register @originalLanguage
      @_registerOriginal = ->

    # Changes original language
    setOriginalLanguage: (lang) ->
      @originalLanguage = lang
      @_registerOriginal()

    # Changes current language.
    # This method sends the following events to the $rootScope:
    # - gr-lang-load - if language data shall be loaded first
    # - gr-lang-load-error - if language data cannot be loaded
    # - gr-lang-changed - when language actually switched and data is loaded
    setLanguage: (lang) ->
      return if lang is @language
      loadAsync = (onLoad) =>
        $rootScope.$broadcast 'gr-lang-load', lang
        asyncLoaders[lang] (error, data) =>
          if error
            console.error(error)
            $rootScope.$broadcas 'gr-lang-load-error', error
          else
            @register(lang, data)
            delete asyncLoaders[lang]
            onLoad()
      loadSync = =>
        @language = lang
        $rootScope.$broadcast 'gr-lang-changed', lang
      if asyncLoaders[lang] then loadAsync -> loadSync() else loadSync()

    # Registers language in service with provided data or async loader.
    # If async loader provided then it will be called before switching to the language.
    # Data format: {key: value}
    # Loader format: function(cb) {... cb(error, data)}
    register: (language, data_or_loader) ->
      throw new Error("language shall be defined!") if not language
      if angular.isFunction(data_or_loader)
        asyncLoaders[language] = data_or_loader
      else
        granula.load wrap(language, data_or_loader)

    # Adds data to the language
    # Same as @register(language, data), here for back compatibility
    # TODO: remove and fix tests
    load: (data, language) ->
      @register(language, data)

    # Adds one key/pattern pair to the language
    # Same as @register(language, {key:pattern})
    save: (key, pattern, language = @originalLanguage) ->
      data = wrap(language)
      data[language][key] = pattern
      granula.load data

    # Returns true if there is pattern for specified key and language
    canTranslate: (key, language = @language) ->
      granula.canTranslate language, key

    compile: (key, language = @language, skipIfEmpty = true) ->
      @_registerOriginal()
      # It is done in order to store argument names from original text
      # before switching to another language (because another language has numeric attributes (like {{1}}) in text
      # and we need to know how to map them)
      if argumentNamesByKey[key] is undefined and language isnt @originalLanguage
        @compile key, @originalLanguage, false
      try
        granula.compile(language, {key}).apply angularInterpolator(mapArgumentByKey(key))
      catch e
        throw e if not skipIfEmpty
        console.error(e.message, e)
        return ""   #continue working

    # Evaluates plural expression with the specified number
    plural: (expression, value) ->
      compiled = peCache[expression] ? (=>
        peCache[expression] = granula.compile(@language, "#{expression}:1")
      )()
      compiled.apply pluralInterpolator(), value

angular.module('granula').filter 'grPluralize', (grService) ->
  (input, pluralExpression) ->
    grService.plural(pluralExpression, input)

angular.module('granula').directive 'grStatus', ->
  (scope, el) ->
    scope.$on 'gr-lang-load', ->
      el.addClass "gr-lang-load"
    scope.$on 'gr-lang-load-error', ->
      el.removeClass "gr-lang-load"
    scope.$on 'gr-lang-changed', ->
      el.removeClass "gr-lang-load"

angular.module('granula').directive 'grLang', ($rootScope, grService, $interpolate, $http)->
  compileScript = (el, attrs) ->
    langName = attrs.grLang
    throw new Error("gr-lang for script element shall have value - name of language") if (langName ? "").length == 0
    if attrs.src
      grService.register langName, (cb) ->
        $http(method: "GET", url: attrs.src).success( (data)=>
          cb(null, data)
        ).error(->
          cb("Cannot load #{attrs.src} for language #{langName}")
        )
    else
      try
        grService.register langName, JSON.parse(el.text())
      catch e
        throw new Error("Cannot parse json for language '#{langName}'", e)

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
      keyExpr = grService.toKey(attrs[attrWithKeyValue], el.attr(attrName))
      interpolateKey = $interpolate(keyExpr, true) if attrs[attrWithKeyValue]
      startKey = if interpolateKey then null else keyExpr
      processDomText grService, $interpolate, interpolateKey, startKey, (->el.attr(attrName)), (val) -> el.attr(attrName, val)
    (scope, el, attrs) ->
      keyListeners = linkFunctions.map (l) -> l.link(scope).onKeyChanged



angular.module('granula').directive 'grKey', (grService, $interpolate) ->
  compile: (el, attrs) ->
    keyExpr = grService.toKey(attrs.grKey, el.text())
    interpolateKey = $interpolate(keyExpr, true) if attrs.grKey
    startKey = if interpolateKey then null else keyExpr
    {link} = processDomText(grService, $interpolate, interpolateKey, startKey, (-> el.text()), ((val) -> el.text(val)))
    (scope, el, attrs) ->
      link scope, attrs
