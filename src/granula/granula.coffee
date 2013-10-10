lang = {}
precompiled = {}

argumentParser = ->
  argument = (argName) ->
    #TODO: configurable outside
    argument: argName
    apply: (context) ->
      val = context[argName]
      if typeof val is 'function' then val() else val

  #TODO: configurable
  startSymbol = "{{"
  endSymbol = "}}"

  nextPosition: (str, from) ->
    str.indexOf(startSymbol, from)
  process: (str, from) ->
    endPos = str.indexOf(endSymbol, from)
    throw new Error("Syntax error: uncompleted argument definition started at char #{from}: #{str} ") if endPos == -1
    part: argument(str.substring(from + startSymbol.length, endPos))
    currentPos: endPos + endSymbol.length

noParser = ->
  nextPosition: -> -1

pluralizerParser = (pluralizeFunction) ->
  return noParser() if not pluralizeFunction
  startSymbol = "("
  endSymbol = ")"
  escape = "\\"
  separator = ","
  wordSeparator = /[\\s,\\.!:;'\"-+=*%$#@]/

  prepare = (word, suffixes) ->
    {word, suffixes} = pluralizeFunction._normalize(word, suffixes) if pluralizeFunction._normalize
    (val) ->
      word + suffixes[pluralizeFunction(val)]

  plural = (word, suffixes, argument) ->
    fn = prepare(word, suffixes)
    apply: (context) ->
      val = argument.apply(context)
      fn(val)


  nextPosition: (str, from) ->
    pos = str.indexOf(startSymbol, from)
    if pos > -1
      pos-- while pos > 0 and str[pos-1].match wordSeparator
    console.log pos, str
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
  apply: -> text

precompile = (text, parsers) ->
  context =
    parts: []
  currentPos = 0
  positions = parsers.map (p) ->p.nextPosition(text, 0)
  isEnd = -> positions.every (pos) -> pos == -1
  while not(isEnd())
    nearestPosition = Math.min.apply(null, positions.filter (p) -> p > -1)
    parserIdx = positions.indexOf(nearestPosition)
    parser = parsers[parserIdx]
    substr = text.substring(currentPos, nearestPosition)
    context.parts.push(justText(substr))
    {part, currentPos} = parser.process text, nearestPosition, context
    context.parts.push(part)
    positions[parserIdx] = parser.nextPosition(text, currentPos)
  context.parts.push(justText(text.substring(currentPos)))
  apply: (args) ->
    ctx = {}
    ctx[idx+1] = arg for arg, idx in args
    (context.parts.map (p) ->p.apply(ctx)).join("")


initPluralization = ->
  pluralization = require('./pluralization')
  for langName, fn of pluralization
    lang[langName] ||= {}
    lang[langName]._pluralize = fn

module.exports =

  load: (langDefinition) ->
    for langName, setOfValues of langDefinition
      lang[langName] ||= {}
      for key, value of setOfValues
        lang[langName][key] = value

  reset: ->
    lang = {}
    precompiled = {}
    initPluralization()

  init: (@options) ->

  translate: (language, key, args...) ->
    @_apply(language, key, args...)


  compile: (language, pattern) ->
    p = precompile(pattern, @_parsers(language))
    (args...) ->p.apply(args)


  _precompiled: (language, key) ->
    return precompiled[language]?[key] ? @_precompile(language, key)

  _parsers: (language) ->
    [argumentParser(), pluralizerParser(lang[language]._pluralize)]

  _precompile: (language, key) ->
    precompiled[language] ||= {}
    precompiled[language]._parsers = @_parsers(language) if not precompiled[language]._parsers
    precompiled[language][key] = precompile(@_get(language, key), precompiled[language]._parsers)

  _apply: (language, key, args...) ->
    @_precompiled(language, key).apply(args)

  _get: (language, key) ->
    throw new Error("Language '#{language}' was not initialized with 'load' method") if not lang[language]
    val = lang[language][key]
    throw new Error("There is no definition for '#{key}' in language '#{language}'") if not val
    val

module.exports.reset()