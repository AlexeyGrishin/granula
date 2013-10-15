checkAttribute = (attribute, cbOnEmpty = ->) ->
  if attribute is undefined or attribute.trim().length == 0
    cbOnEmpty()
    return undefined
  attribute

module.exports =

  textToKey: (text, options = {wordsLimitForKey: 10, replaceSpaces: false}) ->
    return undefined if not text
    text.split(/\s+/).slice(0, options.wordsLimitForKey).join(if options.replaceSpaces then options.replaceSpaces else " ")


  toKey: (attribute, text, options = {textAsKey: 'nokey'}) ->
    switch options.textAsKey
      when true, "always"
        @textToKey(text, options)
      when false, "never"
        checkAttribute attribute, -> throw new Error("Mandatory key attribute is not defined")
      when "nokey"
        checkAttribute(attribute) ? @textToKey(text, options)
      else
        throw new Error("Unknown option '#{options.textAsKey}', possible values: 'never', 'always', 'nokey'")