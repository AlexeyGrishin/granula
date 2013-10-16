{argumentParser, pluralizerParser, justText} = require('./compile/parsers')
{stringInterpolator} = require('./interpolators')
{context} = require('./compile/context')
pluralization = require('./pluralization')()

module.exports = (options) ->

  lang = {}
  precompiled = {}

  defaultInterpolator: stringInterpolator()

  load: (langDefinition) ->
    for langName, setOfValues of langDefinition
      lang[langName] ||= {}
      for key, value of setOfValues
        if key is "_pluralize"
          pluralization.updatePluralization langName, setOfValues._pluralize, setOfValues._normalize
        else if key is "_normalize"
          #do nothing
        else
          lang[langName][key] = value

  translate: (language, key, args...) ->
    @_apply(language, key, args...)

  canTranslate: (language, key) ->
    lang[language]?[key] isnt undefined

  #TODO: translate and compile has different syntax
  compile: (language, pattern) ->
    if pattern.key
      p = @_precompiled(language, pattern.key)
    else
      p = precompile(pattern, @_parsers(language))
    @_applier(p)

  debug: (str, lang = "en") ->
    @compile(lang, str).apply {
      begin: -> console.log("{")
      argument: (ctx, {argName}) -> console.log("  arg: #{argName}")
      pluralExpression: (ctx, {word, suffixes}, {argName}) -> console.log("  plural: #{word}(#{suffixes}):#{argName}")
      string: (ctx, str) -> console.log("  '#{str}'")
      end: -> console.log("}")
    }

  _applier: (precompiled) ->
    fn = (args...) =>
      precompiled.apply(args, @defaultInterpolator)
    fn.apply = (interpolator, args...) ->
      precompiled.apply(args, interpolator)
    fn

  _precompiled: (language, key) ->
    return precompiled[language]?[key] ? @_precompile(language, key)

  _parsers: (language) ->
    [argumentParser(), pluralizerParser((word, suffixes) -> pluralization.preparePluralizationFn(language, word, suffixes))]

  _precompile: (language, key) ->
    precompiled[language] ||= {}
    precompiled[language]._parsers = @_parsers(language) if not precompiled[language]._parsers
    precompiled[language][key] = precompile(@_get(language, key), precompiled[language]._parsers)

  _apply: (language, key, args...) ->
    @_precompiled(language, key).apply(args, @defaultInterpolator)

  _get: (language, key) ->
    throw new Error("Language '#{language}' was not initialized with 'load' method") if not lang[language]
    val = lang[language][key]
    throw new Error("There is no definition for '#{key}' in language '#{language}'") if not val
    val



notEmpty = (str) -> str.length > 0

precompile = (text, parsers) ->
  ctx =
    parts: []

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
    positions.forEach (pos, idx) ->
      if pos < currentPos
        positions[idx] = parsers[idx].nextPosition(text, currentPos)
  remaining = text.substring(currentPos)
  ctx.parts.push(justText(remaining)) if notEmpty(remaining)
  ctx.parts.forEach (part, idx) ->
    part.link(ctx, idx) if part.link


  apply: (args, interpolator) ->
    context(args, interpolator).apply (context)->
      (ctx.parts.map (p) ->p.apply(context)).join("")





