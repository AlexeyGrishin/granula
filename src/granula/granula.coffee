lang = {}
precompiled = {
  shared: {}
}

stringInterpolator = ->
  begin: (context) ->
  string: (context, str) -> str
  argument: (context, {argument, index}) ->
    val = context.attrs[index]
    if typeof val is 'function' then val() else val
  pluralExpression: (context, {fn}, argument) ->
    fn(argument.apply(context))
  end: (context) ->


context = (attributes, interpolator) ->
  ctx = {
    attrs: {}
  }
  for attr, idx in attributes
    ctx.attrs[idx+1] = attr
  noop = ->
  ctx.interpolate = (method, data...) ->
    (interpolator[method] ? noop)(ctx, data...)
  ctx.begin = -> interpolator.begin?(ctx)
  ctx.end = (result) -> interpolator.end?(ctx, result)
  ctx.apply = (fn) ->
    ctx.begin()
    res = fn(ctx)
    ctx.end(res) ? res
  ctx


argumentParser = ->
  argument = (argName, argIdx) ->
    #TODO: configurable outside
    argument: argName
    index: argIdx
    apply: (context) ->
      context.interpolate 'argument', {@argument, @index}

  #TODO: configurable
  startSymbol = "{{"
  endSymbol = "}}"

  nextPosition: (str, from) ->
    str.indexOf(startSymbol, from)
  process: (str, from, context) ->
    endPos = str.indexOf(endSymbol, from)
    throw new Error("Syntax error: uncompleted argument definition started at char #{from}: #{str} ") if endPos == -1
    argName = str.substring(from + startSymbol.length, endPos)
    argIdx = context.getArgumentIndex(argName)
    part: argument(argName, argIdx)
    currentPos: endPos + endSymbol.length

noParser = ->
  nextPosition: -> -1


preparePluralizationFn = (pluralizeFunction, word, suffixes) ->
  {word, suffixes} = pluralizeFunction._normalize(word, suffixes) if pluralizeFunction._normalize
  (val) ->
    word + suffixes[pluralizeFunction(val)]


#TODO: rename pluralizeFunction to pluralizeFormFn
pluralizerParser = (pluralizeFunction) ->
  return noParser() if not pluralizeFunction
  startSymbol = "("
  endSymbol = ")"
  escape = "\\"
  separator = ","
  wordSeparator = /[\s,.!:;'\"-+=*%$#@{}()]/

  plural = (word, suffixes, argument) ->
    fn = preparePluralizationFn(pluralizeFunction, word, suffixes)
    apply: (context) ->
      context.interpolate "pluralExpression", {word, suffixes, fn}, argument


  nextPosition: (str, from) ->
    pos = str.indexOf(startSymbol, from)
    while pos >= from and not str[pos-1].match wordSeparator
      pos--
    pos

  process: (str, from, context) ->
    end = str.indexOf(endSymbol, from)
    pluralExpression = str.substring(from, end)
    parts = pluralExpression.split(startSymbol)
    if parts[0].length > 0 and parts[0].slice(-1) is escape
      part: justText "#{parts[0].slice(0,-1)}#{startSymbol}#{parts[1]}#{endSymbol}"
      currentPos: end + endSymbol.length
    else
      onlyArguments = (context.parts.filter (p) ->p.argument)
      throw new Error("There is no arguments the plural expression '#{pluralExpression}' could be bound to") if onlyArguments.length == 0
      nearestArgument = onlyArguments[onlyArguments.length-1]
      part: plural(parts[0], parts[1].split(separator), nearestArgument)
      currentPos: end + endSymbol.length


justText = (text) ->
  apply: (context) ->
    (context.interpolate "string", text) ? text

notEmpty = (str) -> str.length > 0

precompile = (text, parsers, sharedData) ->
  ctx =
    parts: []
  if not sharedData.mapping
    sharedData.mapping = [null] #to fill 0 index
    ctx.getArgumentIndex = (argName) ->
      sharedData.mapping.push(argName) if sharedData.mapping.indexOf(argName) == -1
      sharedData.mapping.indexOf(argName)
  else
    ctx.getArgumentIndex = (argName) ->
      sharedData.mapping.indexOf(argName)

  currentPos = 0
  positions = parsers.map (p) ->p.nextPosition(text, 0)
  isEnd = -> positions.every (pos) -> pos == -1
  while not(isEnd())
    nearestPosition = Math.min.apply(null, positions.filter (p) -> p > -1)
    parserIdx = positions.indexOf(nearestPosition)
    parser = parsers[parserIdx]
    substr = text.substring(currentPos, nearestPosition)
    ctx.parts.push(justText(substr)) if notEmpty(substr)
    {part, currentPos} = parser.process text, nearestPosition, ctx
    ctx.parts.push(part)
    positions[parserIdx] = parser.nextPosition(text, currentPos)
  remaining = text.substring(currentPos)
  ctx.parts.push(justText(remaining)) if notEmpty(remaining)

  apply: (args, interpolator) ->
    context(args, interpolator).apply (context)->
      (ctx.parts.map (p) ->p.apply(context)).join("")


initPluralization = ->
  pluralization = require('./pluralization')
  for langName, fn of pluralization
    lang[langName] ||= {}
    lang[langName]._pluralize = fn

module.exports =

  defaultInterpolator: stringInterpolator()

  load: (langDefinition) ->
    for langName, setOfValues of langDefinition
      lang[langName] ||= {}
      for key, value of setOfValues
        lang[langName][key] = value

  #TODO: make constructor instead of reset()
  reset: ->
    lang = {}
    precompiled = {shared: {}}
    initPluralization()

  init: (@options) ->


  translate: (language, key, args...) ->
    @_apply(language, key, args...)


  #TODO: translate and compile has different syntax
  compile: (language, pattern) ->
    if pattern.key
      pattern = @_get language, pattern.key
      sharedData = @_sharedData pattern.key
    p = precompile(pattern, @_parsers(language), sharedData ? {})
    @_applier(p)

  _applier: (precompiled) ->
    fn = (args...) =>
      precompiled.apply(args, @defaultInterpolator)
    fn.apply = (interpolator, args...) ->
      precompiled.apply(args, interpolator)
    fn

  _precompiled: (language, key) ->
    return precompiled[language]?[key] ? @_precompile(language, key)

  _parsers: (language) ->
    [argumentParser(), pluralizerParser(lang[language]._pluralize)]

  _precompile: (language, key) ->
    precompiled[language] ||= {}
    precompiled[language]._parsers = @_parsers(language) if not precompiled[language]._parsers
    precompiled[language][key] = precompile(@_get(language, key), precompiled[language]._parsers, @_sharedData(key))

  _sharedData: (key) ->
    precompiled.shared[key] ||= {}
    precompiled.shared[key]

  _apply: (language, key, args...) ->
    @_precompiled(language, key).apply(args, @defaultInterpolator)


  _get: (language, key) ->
    throw new Error("Language '#{language}' was not initialized with 'load' method") if not lang[language]
    val = lang[language][key]
    throw new Error("There is no definition for '#{key}' in language '#{language}'") if not val
    val

module.exports.reset()