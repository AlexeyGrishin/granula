processor = require('../../../src/runner/processor')()
{htmlDocument} = require('../../../src/runner/documents')
_ = require('underscore')


describe "html processor", ->

  log = null

  beforeEach ->
    log =
      errors: []
      warnings: []
      addError: (error) -> @errors.push(error)
      addWarning: (warning) -> @warnings.push(warning)

  defOptions = require('../../../src/runner/defaultOptions')

  expectNoErrorsWarnings = ->
    expect(log.errors).toEqual([])
    expect(log.warnings).toEqual([])

  describe "when only marked tags shall be collected", ->
    htmlDoc = null
    beforeEach ->
      htmlDoc = htmlDocument(
        """
        <div>
          <p gr-key='key1'>value1</p>
          <p gr-key='key2'>value2</p>
          <p gr-key>key3</p>
          <p>notakey</p>
        </div>
        """)

    it "shall collect keys from marked elements", ->
      res = {}
      processor.processHtml res, htmlDoc, _.extend({}, defOptions, {textAsKey: "always"}), log
      expect(res).toEqual {
        value1: "value1"
        value2: "value2"
        key3: "key3"
      }
      expectNoErrorsWarnings()

    it "shall use text as keys if corresponding option is on", ->
      res = {}
      processor.processHtml res, htmlDoc, defOptions, log
      expect(res).toEqual {
        key1: "value1"
        key2: "value2"
        key3: "key3"
      }
      expectNoErrorsWarnings()

    it "shall collect attributes as well", ->
      htmlDoc = htmlDocument """<div gr-attrs='title' gr-key-title='key5' title='value5'>Hello!</div> """
      res = {}
      processor.processHtml res, htmlDoc, defOptions, log
      expect(res).toEqual {
        key5: "value5"
      }
      expectNoErrorsWarnings()

    it "shall add warnings for elements with childnodes", ->
      htmlDoc = htmlDocument """<div gr-key='key1'>This is <b>value</b></div>"""
      res = {}
      processor.processHtml res, htmlDoc, defOptions, log
      expect(res).toEqual {}
      expect(log.errors.length).toEqual(1)

