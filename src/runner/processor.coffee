granulaCtor = require('../granula/granula')
_ = require('underscore')
keys = require('../granula/keys')

ATTRS_TO_TRANSLATE = ["title", "alt", "placeholder"]
TAGS_TO_IGNORE = ["script", "link", "style"]
ATTR_TO_IGNORE = "gr-skip"

#TODO: do not process empty elements
#TODO: exclude {{}} from keys?
module.exports = ->
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


    elementIterator = {
      shallProcess: if options.onlyMarked then shallProcess.marked else shallProcess.all,
      getAttrs: if options.onlyMarked then getAttrs.marked else getAttrs.all,
      getKey:  (text, attribute, path) ->
        try
          keys.toKey(attribute, text, options)
        catch e
          log.addError e.message + " (#{path()}"

      shallProcessElement: (element) ->
        not _.contains(TAGS_TO_IGNORE, element.name) and
          not htmlDocument.hasAttribute(element, ATTR_TO_IGNORE) and
          @shallProcess(element)

      process: (element) ->
        return if not @shallProcessElement(element)
        #1 - text
        if htmlDocument.hasAttribute(element, 'gr-key')
          textNodes = htmlDocument.getText(element)#TODO: process other text nodes as well, or add warning
          hasChildren = htmlDocument.getChildNodes(element).length > 0
          if hasChildren
            log.addError("Element has subnodes. Unfortunately granula does not support such case yet, please add gr-key to each of subnodes separately or wrap your text nodes in some elements : #{htmlDocument.getPath(element)}, subnodes: #{_.pluck(element.children, 'name').join(',')}")
            return
          if textNodes.length > 1
            log.addWarning("Element has more than 1 text node, only first will be processed: #{htmlDocument.getPath(element)}")
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

