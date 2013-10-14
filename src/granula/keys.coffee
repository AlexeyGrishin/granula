module.exports =

  textToKey: (text, options = {wordsLimitForKey: 10, replaceSpaces: false}) ->
    return undefined if not text
    text.split(/\s+/).slice(0, options.wordsLimitForKey).join(if options.replaceSpaces then options.replaceSpaces else " ")