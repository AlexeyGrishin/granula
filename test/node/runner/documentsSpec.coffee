{htmlDocument} = require('../../../src/runner/documents')
_ = require('underscore')

describe 'htmlDocument parser', ->

  first = (doc) ->
    firstChild = null
    doc.forEach (e) -> firstChild = e if not firstChild
    firstChild

  it "shall correctly get text for node", ->
    doc = htmlDocument """<b>text<c>one</c></b>"""
    expect(doc.getText(first(doc))).toEqual("textone")

  it "shall correctly get html for node", ->
    doc = htmlDocument """<b>text<c d='f'>one</c></b>"""
    expect(doc.getHtml(first(doc))).toEqual("""<b>text<c d="f">one</c></b>""")

  it "shall correctly get inner html", ->
    doc = htmlDocument """<b>text<c d='f'>one</c></b>"""
    expect(doc.getInnerHtml(first(doc))).toEqual("""text<c d="f">one</c>""")
