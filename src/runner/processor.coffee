granulaCtor = require('../granula/granula')
_ = require('underscore')
keys = require('../granula/keys')

ATTRS_TO_TRANSLATE = ["title", "alt", "placeholder"]
TAGS_TO_IGNORE = ["script", "link", "style"]
ATTR_TO_IGNORE = "gr-skip"

#TODO: do not process empty elements
#TODO: exclude {{}} from keys?
module.exports = ->
  #htmlDocument =
  # forEach: (element) ->
  # getText: (element) ->
  # getAttribute: (element, attrName) ->
  # setAttribute: (element, attrName) ->
  #options =
  # onlyMarked: true/false
  # textAsKey: "always" == true, "nokey", false == "never"
  # warnings: ["subtags"]
  # wordsLimitForKey: 10
  granula = granulaCtor()

  hasSomethingToTranslate = (str) ->
    return false if not str
    something = false
    granula.compile("en", str).apply {
      string: (ctx, str) ->
        if str.replace(/\s+/gi, '').length > 0
          something = true
      pluralExpression: ->
        something = true
    }
    something

  processHtml: (lang, htmlDocument, options, log) ->
    options = _.defaults(options, {
      onlyMarked: true,
      textAsKey: "nokey",
      warnings: ["subtags"],
      wordsLimitForKey: 10,
      replaceSpaces: false,
      attrsToTranslate: ATTRS_TO_TRANSLATE
    })

    shallProcess =
      marked: (element) -> htmlDocument.hasAttribute(element, "gr-key") or htmlDocument.hasAttribute(element, "gr-attrs")
      all: (element) -> true

    getAttrs =
      marked: (element) -> htmlDocument.getAttribute(element, "gr-attrs")?.split(",") ? []
      all: (element) -> options.attrsToTranslate.filter (attr) -> htmlDocument.hasAttribute(element, attr)

    getKey =
      alwaysFromText: (text, attribute, path) ->
        keys.textToKey(text, options)
      alwaysFromAttribute: (text, attribute, path) ->
        if attribute is undefined
          log.addError "Element that shall be translated does not have lang key: #{path()}: '#{text}'"
        attribute
      fromAttributeIfDefined: (text, attribute, path) ->
        res = attribute ? keys.textToKey(text, options)
        if not res
          log.addError "Element that shall be translated does not have lang key or text that shall be used instead: #{path()}"
        res



    elementIterator = {
      shallProcess: if options.onlyMarked then shallProcess.marked else shallProcess.all,
      getAttrs: if options.onlyMarked then getAttrs.marked else getAttrs.all,
      getKey: switch options.textAsKey
        when true, "always" then getKey.alwaysFromText
        when false, "never" then getKey.alwaysFromAttribute
        when "nokey" then getKey.fromAttributeIfDefined
        else throw new Error("Unexpected value for 'textAsKey' option - '#{options.textAsKey}'. Expected - true, 'always', 'nokey', 'never', false")

      shallProcessElement: (element) ->
        not _.contains(TAGS_TO_IGNORE, element.name) and
          not htmlDocument.hasAttribute(element, ATTR_TO_IGNORE) and
          @shallProcess(element)

      process: (element) ->
        return if not @shallProcessElement(element)
        #1 - text
        textNodes = htmlDocument.getText(element)#TODO: process other text nodes as well, or add warning
        if textNodes.length > 1
          log.addWarning("Element has more than 1 text node, only first will be processed: #{htmlDocument.getPath(element)}")
          console.log (textNodes.map (tn) -> "  >> #{tn} <<").join("\n")
        text = textNodes[0]
        if hasSomethingToTranslate(text)
          key = @getKey text, htmlDocument.getAttribute(element, "gr-key"), -> htmlDocument.getPath(element)
          @processKey(key, text)
        #2 - attrs
        attrs = @getAttrs(element)
        attrs.forEach (attrName) =>
          text = htmlDocument.getAttribute(element, attrName)
          if hasSomethingToTranslate(text)
            key = htmlDocument.getAttribute(element, "gr-key-#{attrName}")
            key = @getKey text, key, -> htmlDocument.getPath(element) + " / @#{attrName}"
            @processKey(key, text)

      processKey: (key, text) ->
        if lang[key]
          log.addWarning("Key '#{key}' met again with another value: was '#{lang[key]}', now '#{text}'") if lang[key] != text
        else
          lang[key] = text

    }



    htmlDocument.forEach (e) -> elementIterator.process(e)

