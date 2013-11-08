granulaCtor = (require('../granula/granula'))
keys = require('../granula/keys')

angular.module('granula', [])

defaultOptions = require('../runner/defaultOptions')

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
      return if lang is @language and not asyncLoaders[lang]
      return if asyncLoaders[lang]?.loading
      @_loading = lang
      loadAsync = (onLoad) =>
        $rootScope.$broadcast 'gr-lang-load', lang
        asyncLoaders[lang].loading = asyncLoaders[lang].length
        asyncLoaders[lang].forEach (loader) =>
          loader (error, data) =>
            if error
              console.error(error)
              $rootScope.$broadcast 'gr-lang-load-error', error
            else
              @register(lang, data)
              asyncLoaders[lang].loading--
              if asyncLoaders[lang].loading == 0
                delete asyncLoaders[lang]
                onLoad()
      loadSync = =>
        return if lang != @_loading
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
        asyncLoaders[language] ?= []
        asyncLoaders[language].push(data_or_loader)
      else
        granula.load wrap(language, data_or_loader)

    # Adds one key/pattern pair to the language
    # Same as @register(language, {key:pattern})
    save: (key, pattern, language = @originalLanguage) ->
      data = wrap(language)
      data[language][key] = pattern
      granula.load data

    # Returns true if there is pattern for specified key and language
    canTranslate: (key, language = @language) ->
      granula.canTranslate language, key

    # Returns true if there is data (even loading) for specified language
    canTranslateTo: (language = @language) ->
      granula.canTranslateTo(language) or asyncLoaders[language]

    # To use in javascript services, controllers, etc. Options may contain:
    # - key (see below)
    # - language - if not defined then current will be used
    # Depending on options provided in grServiceProvider.config
    # - if textAsKey == 'never' then key is required and will be used
    # - if textAsKey == 'nokey' then key is not required and, if absent, text will be used instead
    # - if textAsKey == 'always' then key will be ignored
    # Returns empty string while there is ongoing loading
    #TODO: untested!
    translate: (pattern, options = {}, args...) ->
      if angular.isObject(pattern)
        options = pattern
        pattern = null
      if angular.isObject(options)
        angular.extend options, {@language}
      else
        args.unshift(options)
        options = {@language}
      return "" if asyncLoaders[options.language]
      realKey = @toKey options.key, pattern
      if @isOriginal() and pattern
        @save realKey, pattern, options.language
      granula.translate options.language, realKey, args

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
        if not asyncLoaders[language]
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
    undefined #otherwise it returns response from register call and angular decides it is link function...

  compileOther = (el, attrs) ->
    grService.setOriginalLanguage attrs.grLangOfText if attrs.grLangOfText
    requireInterpolation = $interpolate(attrs.grLang, true)
    if requireInterpolation or not grService.canTranslateTo(attrs.grLang)
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



processDomText = (grService, $interpolate, interpolateKey, startKey, readTextFn, writeTextFn, el) ->
  pattern = readTextFn(el)
  if startKey
    grService.save startKey, pattern
    compiled = grService.compile(startKey)
    interpolateFn = $interpolate(compiled, true)
  if interpolateFn or interpolateKey
    writeTextFn(el, '') # to prevent auto-binding made by angular.js

  link: (scope, el) ->
    outputFn = interpolateFn
    key = startKey

    onLanguageChanged = () ->
      outputFn = $interpolate(grService.compile(key))
      writeTextFn(el, outputFn(scope))

    onVariablesChanged = (text) ->
      return writeTextFn(el, text) if grService.language is grService.originalLanguage
      throw new Error("outputFn is undefined but it shall not be") if not outputFn
      writeTextFn(el, outputFn(scope))

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





angular.module('granula').directive 'grAttrs', (grService, $interpolate) ->
  read = (attrName) -> (el) ->el.attr(attrName)
  write = (attrName) -> (el, val) -> el.attr(attrName, val)

  compile: (el, attrs) ->
    attrNames = attrs.grAttrs.split(",")
    linkFunctions = attrNames.map (attrName) ->
      attrWithKeyValue = "grKey#{attrName[0].toUpperCase() + attrName.substring(1)}"
      keyExpr = grService.toKey(attrs[attrWithKeyValue], el.attr(attrName))
      interpolateKey = $interpolate(keyExpr, true) if attrs[attrWithKeyValue]
      startKey = if interpolateKey then null else keyExpr
      {
        link: processDomText(grService, $interpolate, interpolateKey, startKey, read(attrName), write(attrName), el).link
        attrName: attrName
      }
    (scope, el, attrs) ->
      keyListeners = linkFunctions.map (l) -> l.link(scope, el).onKeyChanged



angular.module('granula').directive 'grKey', (grService, $interpolate) ->
  read = (el) -> el.html()
  write =(el, val) -> el.html(val)
  compile: (el, attrs) ->
    keyExpr = grService.toKey(attrs.grKey, el.text())
    interpolateKey = $interpolate(keyExpr, true) if attrs.grKey
    startKey = if interpolateKey then null else keyExpr
    {link} = processDomText(grService, $interpolate, interpolateKey, startKey, read, write, el)
    (scope, el, attrs) ->
      link scope, el
