justText = (text) ->
  apply: (context) ->
    (context.interpolate "string", text) ? text

argument = (argName) ->
  argName: argName
  apply: (context) ->
    context.interpolate 'argument', {argName}

argumentParser = (startSymbol = "{{", endSymbol = "}}" )->

  nextPosition: (str, from) ->
    str.indexOf(startSymbol, from)
  process: (str, from, context) ->
    endPos = str.indexOf(endSymbol, from)
    throw new Error("Syntax error: uncompleted argument definition started at char #{from}: #{str} ") if endPos == -1
    argName = str.substring(from + startSymbol.length, endPos)
    part: argument(argName)
    currentPos: endPos + endSymbol.length

noParser = ->
  nextPosition: -> -1

pluralPartsToString = (word, suffixes) ->
  "#{word}(#{suffixes.join(',')})"

pluralizerParser = (preparePluralizationFn) ->
  return noParser() if not preparePluralizationFn
  startSymbol = "("
  endSymbol = ")"
  escape = "\\"
  separator = ","
  wordSeparator = /[\s,.!:;'\"-+=*%$#@{}()]/
  varEnd = /[\s,!:;'\"-+=*%$#@{}()]/    #same as wordSeparator but without '.' which is widely used in angular expressions
  exactVarSpec = ":"
  nearestRight = ">"

  plural = (word, suffixes, argName) ->
    fn = preparePluralizationFn(word, suffixes)

    argument: if (typeof argName is "string") then argument(argName) else null
    apply: (context) ->
      context.interpolate "pluralExpression", {word, suffixes, fn}, @argument
    link: (context, myIdx) ->
      return if @argument isnt null

      if argName.prev == true
        searchIn = [myIdx..0]
        dir = "left"
      else if argName.next == true
        searchIn = [myIdx..context.parts.length-1]
        dir = "right"
      else
        throw new Error("invalid link #{argName} - expected {prev:true} or {next:true}")

      for i in searchIn
        if context.parts[i].argName
          @argument = context.parts[i]
          break
      throw new Error("There is no argument nearest to the #{dir} for plural expression '#{pluralPartsToString(word, suffixes)})'") if @argument is null

  nextPosition: (str, from) ->
    pos = str.indexOf(startSymbol, from)
    while pos >= from and not (str[pos-1] ? ' ').match wordSeparator
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
      argLink = {prev: true}
      cPos = end + endSymbol.length
      if (str[end + endSymbol.length]) == exactVarSpec
        startVar = end + endSymbol.length + 1
        end = startVar
        end++ while end < str.length and not str[end].match varEnd
        exactVar = str.substring(startVar, end)
        if exactVar == nearestRight
          argLink = {next: true}
          cPos = end
        else if exactVar.length > 0
          argLink = exactVar
          cPos = end


      part: plural(parts[0], parts[1].split(separator), argLink)
      currentPos: cPos

module.exports = {argumentParser, pluralizerParser, justText}