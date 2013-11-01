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

  root: -> dom

  getText: (element) ->
    nodeToText = (parts, element) ->
      parts.push(element.data) if element.type == 'text'
      for child in element.children ? []
        nodeToText parts, child
      parts

    nodeToText([], element).join("")

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


  getInnerHtml: (element) ->
    parts = []
    for child in element.children
      nodeToHtml parts, child
    parts.join("")

  getHtml: (element) ->
    nodeToHtml([], element).join("")


nodeStart = (parts, element) ->
  parts.push "<#{element.name}"
  for attr, val of element.attribs
    parts.push " #{attr}"
    parts.push "=\"#{val}\"" if attr != val and not _.isEmpty(val)
  parts.push ">"
nodeEnd = (parts, element) ->
  parts.push "</#{element.name}>"
nodeToHtml = (parts, element) ->
  parts.push element.data if element.type == 'text'
  return if element.type != 'tag'
  nodeStart parts, element
  for child in element.children ? []
    nodeToHtml parts, child
  nodeEnd parts, element
  parts
