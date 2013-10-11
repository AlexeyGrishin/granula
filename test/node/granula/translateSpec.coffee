
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
    beforeEach ->
      granula.reset()
      granula.load {ru: {}}
      @expr3 = granula.compile("ru", "{{1}} медвед(ь,я,ей)")
      @expr2 = granula.compile("ru", "{{1}} утка(ки,ок)")
      @expr1 = granula.compile("ru", "{{1}} сапог(а)")

    expectForm1 = (expr, template) ->
      for x in [1,21]
        expect(expr(x)).toEqual("#{x} #{template}")

    expectForm2 = (expr, template) ->
      for x in [2..4].concat [22..24]
        expect(expr(x)).toEqual("#{x} #{template}")

    expectForm3 = (expr, template) ->
      for x in [5..20].concat [25]
        expect(expr(x)).toEqual("#{x} #{template}")

    describe "for all 3 forms specified", ->

      it "shall return 1st form for value == 1 or 21", ->
        expectForm1 @expr3, "медведь"

      it "shall return 2st form for value == 2-4,22-24", ->
        expectForm2 @expr3, "медведя"

      it "shall return 3st form for value == 5-20,25", ->
        expectForm3 @expr3, "медведей"

    describe "for 2 forms specified", ->

      it "shall return 1st form for value == 1 or 21", ->
        expectForm1 @expr2, "утка"

      it "shall return 2st form for value == 2-4,22-24", ->
        expectForm2 @expr2, "утки"

      it "shall return 3st form for value == 5-20,25", ->
        expectForm3 @expr2, "уток"

    describe "for 1 form specified", ->

      it "shall return 1st form for value == 1 or 21", ->
        expectForm1 @expr1, "сапог"

      it "shall return 2st form for value == 2-4,22-24", ->
        expectForm2 @expr1, "сапога"

      it "shall return 3st form for value == 5-20,25", ->
        expectForm3 @expr1, "сапог"


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

describe "granula.compile", ->

  beforeEach ->
    granula.reset()
    granula.load {en:{
      key1: "{{1}} cat(s)"
    }}
    @addMatchers
      toBeFunction: ->
        Object.prototype.toString.call(this.actual)=='[object Function]'

  it "shall produce function", ->
    expect(granula.compile("en", "{{1}} word(s)")).toBeFunction()

  it "shall produce function which converts expression to string", ->
    expect(granula.compile("en", "{{1}} word(s)")(6)).toEqual("6 words")

  it "shall accept key as well", ->
    expect(granula.compile("en", key:"key1")(1)).toEqual("1 cat")


  describe "shall acccept custom interpolator", ->
    customInterpolator = null
    beforeEach ->
      customInterpolator = jasmine.createSpyObj("interpolator", ["begin", "end", "string", "argument", "pluralExpression"])
      customInterpolator.string.andReturn("1")
      customInterpolator.argument.andReturn("2")
      customInterpolator.pluralExpression.andReturn("3")

    it "which shall be called for simple text", ->
      granula.compile("en", "text").apply customInterpolator
      expect(customInterpolator.string).toHaveBeenCalledWith(jasmine.any(Object), "text")
      expect(customInterpolator.argument).not.toHaveBeenCalled()
      expect(customInterpolator.pluralExpression).not.toHaveBeenCalled()

    it "which shall be called for argument", ->
      granula.compile("en", "{{x}}").apply customInterpolator
      expect(customInterpolator.argument).toHaveBeenCalledWith(jasmine.any(Object), {argument:"x", index: 1})
      expect(customInterpolator.string).not.toHaveBeenCalled()
      expect(customInterpolator.pluralExpression).not.toHaveBeenCalled()

    it "which shall be called for plural expression", ->
      granula.compile("en", "{{y}}word(s)").apply customInterpolator
      expect(customInterpolator.argument).toHaveBeenCalledWith(jasmine.any(Object), {argument:"y", index: 1})
      console.log customInterpolator.string.mostRecentCall.args
      expect(customInterpolator.string).not.toHaveBeenCalled()
      expect(customInterpolator.pluralExpression).toHaveBeenCalled()

    it "which shall be called for plural expression with plural function and related argument", ->
      granula.compile("en", "{{x}}{{y}}word(s)").apply customInterpolator
      pluralExpression = customInterpolator.pluralExpression.mostRecentCall.args[1]
      argument = customInterpolator.pluralExpression.mostRecentCall.args[2]
      expect(pluralExpression.word).toEqual("word")
      expect(pluralExpression.suffixes).toEqual(["s"])
      expect(pluralExpression.fn(2)).toEqual("words")
      expect(argument.argument).toEqual("y")

    it "which shall be called before processing", ->
      granula.compile("en", "a").apply customInterpolator
      expect(customInterpolator.begin).toHaveBeenCalled()

    it "which shall be called after processing", ->
      res = granula.compile("en", "a").apply customInterpolator
      expect(customInterpolator.end).toHaveBeenCalled()

    it "which may return new result in 'end' method", ->
      customInterpolator.string.andReturn "cde"
      customInterpolator.end.andReturn "test"
      res = granula.compile("en", "a").apply customInterpolator
      expect(res).toEqual("test")

    it "which shall return interpolation concatenation if 'end' method returns undefined", ->
      customInterpolator.string.andReturn "cde"
      customInterpolator.end.andReturn undefined
      res = granula.compile("en", "abc").apply customInterpolator
      expect(res).toEqual("cde")

    it "even there is no methods", ->
      emptyInterpolator = {}
      res = granula.compile("en", "there is {{0}} method(s) here").apply emptyInterpolator, 4
      expect(res).toEqual("there is   here")


