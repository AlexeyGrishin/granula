htmlparser2 = require('htmlparser2')
_ = require('underscore')

emptyIsUndefined = (str) ->
  if str?.length == 0 then undefined else str

module.exports.htmlDocument = (html) ->
  dom = null
  handler = new htmlparser2.DomHandler ((e, adom) ->
    #TODO: errors
    dom = adom
  ), normalizeWhitespace: true
  parser = new htmlparser2.Parser(handler)
  parser.write(html)
  parser.done()

  processWithChildren: (element, cb) ->
    cb(element)
    (element.children ? []).forEach (ch) => @processWithChildren(ch, cb)

  forEach: (action) ->
    dom.forEach (el) => @processWithChildren(el, action)

  getText: (element) ->
    element.children?.filter((ch) -> ch.type=='text').filter((ch)->ch.data.trim().length > 0).map((ch) -> ch.data) ? []

  getChildNodes: (element) ->
    element.children?.filter((ch) -> ch.type != 'text') ? []


  hasAttribute: (element, attribute) ->
    element.attribs?[attribute] isnt undefined

  getAttribute: (element, attribute) ->
    emptyIsUndefined(element.attribs?[attribute])

  getPath: (element) ->
    parts = []
    while element
      parts.unshift(element)
      element = element.parent
    args = (element) ->
      _.pairs(_.pick(element.attribs, "id", "class")).map(([name, val])-> "#{name}=\"#{val}\"").join(" ")
    parts.map((e) -> "<#{e.name} #{args(e)}>").join(" / ")



