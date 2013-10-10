
granula = (require '../../../src/granula/granula')
pluralization = (require '../../../src/granula/pluralization')

describe "pluralization functions", ->

  describe "for english", ->

    beforeEach ->
      granula.reset()
      granula.load {en: {}}
      @expr = granula.compile("en", "{{1}} word(s)")

    it "shall return 1st form for value == 1", ->
      expect(@expr(1)).toEqual("1 word")
    it "shall return 2nd form for value == 2", ->
      expect(@expr(2)).toEqual("2 words")
    it "shall return 2nd form for value == 0", ->
      expect(@expr(0)).toEqual("0 words")

    it "shall use '' as 2nd form by default", ->
      expr = granula.compile("en", "{{1}} word()")
      expect(expr(1)).toEqual("1 word")
      expect(expr(2)).toEqual("2 word")

  describe "for russian", ->

describe 'granula.translate', ->

  beforeEach ->
    granula.reset()

  init = (key, lang1, lang2) ->
    lang = lang1: {}, lang2: {}
    lang.lang1[key] = lang1
    lang.lang2[key] = lang2
    granula.load lang

  it 'shall perform simple translation by key', ->
    init "hello1", "hello", "привет"
    expect(granula.translate("lang2", "hello1")).toEqual("привет")

  it "shall substitute string arguments", ->
    init "hello1", "hello {{1}}", "привет {{1}}"
    expect(granula.translate("lang1", "hello1", "Alex")).toEqual("hello Alex")

  it "shall substitute function arguments", ->
    init "hello1", "hello {{1}}", "привет {{1}}"
    expect(granula.translate("lang1", "hello1", ->"Alex")).toEqual("hello Alex")

  describe "in case of 2 pluralization forms", ->

    beforeEach ->
      granula.reset()

    initPluralization = (key, lang1, pluralizationFunction) ->
      lang = lang1: {}
      lang.lang1[key] = lang1
      lang.lang1._pluralize = pluralizationFunction
      granula.load lang

    simpleFunction = (number) ->
      if number == 1 then 0 else 1

    simpleFunction._normalize = (word, suffixes) ->
      word: word
      suffixes: switch suffixes.length
        when 0 then ["", "s"]
        when 1 then ["", suffixes[0]]
        else suffixes

    describe "when pluralization expression is escaped", ->
      it "shall be ignored", ->
        initPluralization "key", "It's free \\(really!)", simpleFunction
        expect(granula.translate("lang1", "key")).toEqual("It's free (really!)")

    describe "when pluralization expression contains only 1 form", ->
      beforeEach ->
        initPluralization "errors", "{{1}} error(s)", simpleFunction

      it "shall select singular form if nearest left value is singular", ->
        expect(granula.translate("lang1", "errors", 1)).toEqual("1 error")

      it "shall select plural form if nearest left value is plural", ->
        expect(granula.translate("lang1", "errors", 2)).toEqual("2 errors")


    describe "when pluralization expression contains only both forms", ->
      beforeEach ->
        initPluralization "mouse", "{{1}} (mouse,mice)", simpleFunction

      it "shall select singular form if nearest left value is singular", ->
        expect(granula.translate("lang1", "mouse", 1)).toEqual("1 mouse")

      it "shall select plural form if nearest left value is plural", ->
        expect(granula.translate("lang1", "mouse", 2)).toEqual("2 mice")

