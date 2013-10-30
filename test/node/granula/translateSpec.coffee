
granulaCtor = (require '../../../src/granula/granula')
pluralization = (require '../../../src/granula/pluralization')


compiled = ->
  parts: []
  toString: -> @parts.join(" + ")
  arg: (name) ->
    @parts.push name
    @
  str: (str) ->
    @parts.push "'#{str}'"
    @
  pe: (ex, arg) ->
    @parts.push "#{ex}:#{arg}"
    @

matchers  = (granula)->
  toBeCompiledInto: (expectedExpr) ->
    actParts = compiled()
    granula.compile("en", @actual).apply {
      argument: (ctx, {argName}) ->
        actParts.arg(argName)
      string: (ctx, str) ->
        actParts.str(str)
      pluralExpression: (ctx, {word, suffixes}, {argName}) ->
        actParts.pe("#{word}(#{suffixes.join(',')})", argName)
    }
    @message = null
    for part, idx in expectedExpr.parts
      if actParts.parts[idx] != part
        @message = -> "Expected that '#{@actual}' will be compiled into\n#{expectedExpr}\n  but it was compiled into\n#{actParts}\n - at least '#{actParts.parts[idx]}' shall be '#{part}' "
        break
    @message == null

granula = null

describe "pluralization functions", ->

  describe "for unknown language", ->
    beforeEach ->
      granula = granulaCtor()

    it "shall work as for english and assume 2 forms", ->
      expt = granula.compile("ua", "{{1}} гудзик(iв)")
      expect(expt(1)).toEqual("1 гудзик")
      expect(expt(2)).toEqual("2 гудзикiв")

  describe "for english", ->

    beforeEach ->
      granula = granulaCtor()
      granula.load {en: {}}
      @expr = granula.compile("en", "word(s):1")

    it "shall return 1st form for value == 1", ->
      expect(@expr(1)).toEqual("word")
    it "shall return 2nd form for value == 2", ->
      expect(@expr(2)).toEqual("words")
    it "shall return 2nd form for value == 0", ->
      expect(@expr(0)).toEqual("words")

    it "shall use '' as 2nd form by default", ->
      expr = granula.compile("en", "word():1")
      expect(expr(1)).toEqual("word")
      expect(expr(2)).toEqual("word")

  describe "for russian", ->
    beforeEach ->
      granula = granulaCtor()
      granula.load {ru: {}}
      @expr3 = granula.compile("ru", "медвед(ь,я,ей):1")
      @expr2 = granula.compile("ru", "утка(ки,ок):1")
      @expr1 = granula.compile("ru", "сапог(а):1")

    expectForm1 = (expr, template) ->
      for x in [1,21]
        expect(expr(x)).toEqual("#{template}")

    expectForm2 = (expr, template) ->
      for x in [2..4].concat [22..24]
        expect(expr(x)).toEqual("#{template}")

    expectForm3 = (expr, template) ->
      for x in [5..20].concat [25]
        expect(expr(x)).toEqual("#{template}")

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
    granula = granulaCtor()

  init = (key, lang1, lang2 = "") ->
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

  it "shall substitute string arguments in valid order", ->
    init "h1", "{{2}} {{1}} {{2}}"
    expect(granula.translate("lang1", "h1", "or not", "to be")).toEqual("to be or not to be")

  it "shall substitute string arguments by name if they provided as struct", ->
    init "h1", "{{x}} {{y}}"
    expect(granula.translate("lang1", "h1", {x:2, y:'cats'})).toEqual("2 cats")

  describe "in case of custom pluralization function for 2 pluralization forms", ->

    beforeEach ->
      granula = granulaCtor()
      @addMatchers matchers(granula)

    initPluralization = (key, lang1, pluralizationFunction, normalizationFunction) ->
      lang = lang1: {}
      lang.lang1[key] = lang1
      lang.lang1._pluralize = pluralizationFunction
      lang.lang1._normalize = normalizationFunction
      granula.load lang

    simpleFunction = (number) ->
      if number == 1 then 0 else 1

    _normalize = (word, suffixes) ->
      word: word
      suffixes: switch suffixes.length
        when 0 then ["", "s"]
        when 1 then ["", suffixes[0]]
        else suffixes

    describe "when pluralization expression is escaped", ->
      it "shall be ignored", ->
        initPluralization "key", "It's free \\(really!)", simpleFunction, _normalize
        expect(granula.translate("lang1", "key")).toEqual("It's free (really!)")

    describe "when pluralization expression is found inside variable", ->

      it "shall be ignored", ->
        expect("{{abc(s)}} abc(s)").toBeCompiledInto(compiled().arg("abc(s)").str(" ").pe("abc(s)", "abc(s)"))
        initPluralization "key", "{{abc(s)}} abc(s)", simpleFunction, _normalize
        expect(granula.translate("lang1", "key", {"abc(s)": 2})).toEqual("2 abcs")

    describe "when pluralization expression contains only 1 form", ->
      beforeEach ->
        initPluralization "errors", "{{1}} error(s)", simpleFunction, _normalize

      it "shall select singular form if nearest left value is singular", ->
        expect(granula.translate("lang1", "errors", 1)).toEqual("1 error")

      it "shall select plural form if nearest left value is plural", ->
        expect(granula.translate("lang1", "errors", 2)).toEqual("2 errors")


    describe "when pluralization expression contains only both forms", ->
      beforeEach ->
        initPluralization "mouse", "{{1}} (mouse,mice)", simpleFunction, _normalize

      it "shall select singular form if nearest left value is singular", ->
        expect(granula.translate("lang1", "mouse", 1)).toEqual("1 mouse")

      it "shall select plural form if nearest left value is plural", ->
        expect(granula.translate("lang1", "mouse", 2)).toEqual("2 mice")

describe "granula.compile", ->

  beforeEach ->
    granula = granulaCtor()
    granula.load {en:{
      key1: "{{1}} cat(s)"
    }}
    @addMatchers
      toBeFunction: ->
        Object.prototype.toString.call(this.actual)=='[object Function]'
    @addMatchers matchers(granula)

  it "shall produce function", ->
    expect(granula.compile("en", "{{1}} word(s)")).toBeFunction()

  it "shall produce function which converts expression to string", ->
    expect(granula.compile("en", "{{1}} word(s)")(6)).toEqual("6 words")

  it "shall accept key as well", ->
    expect(granula.compile("en", key:"key1")(1)).toEqual("1 cat")

  #TODO: test using toBeCompiledInto
  #   {{x}}
  #   {{x}}word(s)
  #   word(s){{x}}
  #   word(s)
  #   word(s):x
  #   word(s):> {{x}}
  #   {{x}} {{y}} word(s)

  it "shall link to nearest variable on the left if not specified explicitly", ->
    expect("{{1}}{{2}}word(s){{3}}").toBeCompiledInto(compiled().arg("1").arg("2").pe("word(s)", "2").arg("3"))

  it "shall throw error if there is no variable on left", ->
    expect(->granula.compile("en", "word(s)")).toThrow()

  it "shall link to nearest variable on the right if specified explicitly", ->
    expect("There (is,are):> {{n}} item(s)").toBeCompiledInto(compiled()
      .str("There ")
      .pe("(is,are)", "n")
      .str(" ")
      .arg("n")
      .str(" ")
      .pe("item(s)", "n")
    )

  it "shall ignore empty variable name", ->
    expect("{{x}}error(s):").toBeCompiledInto(compiled()
      .arg("x").pe("error(s)", "x")
    )

  it "shall link to specified explicitly variable", ->
    expect("{{x}}{{y}}error(s):x").toBeCompiledInto(compiled()
      .arg("x").arg("y").pe("error(s)", "x")
    )
  it "shall link to specified explicitly variable even it is not included into pattern", ->
    expect("error(s):e here").toBeCompiledInto(compiled()
      .pe("error(s)", "e").str(" here")
    )


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
      expect(customInterpolator.argument).toHaveBeenCalledWith(jasmine.any(Object), {argName:"x"})
      expect(customInterpolator.string).not.toHaveBeenCalled()
      expect(customInterpolator.pluralExpression).not.toHaveBeenCalled()

    it "which shall be called for plural expression", ->
      granula.compile("en", "{{y}}word(s)").apply customInterpolator
      expect(customInterpolator.argument).toHaveBeenCalledWith(jasmine.any(Object), {argName:"y"})
      expect(customInterpolator.string).not.toHaveBeenCalled()
      expect(customInterpolator.pluralExpression).toHaveBeenCalled()

    it "which shall be called for plural expression with plural function and related argument", ->
      granula.compile("en", "{{x}}{{y}}word(s)").apply customInterpolator
      pluralExpression = customInterpolator.pluralExpression.mostRecentCall.args[1]
      argument = customInterpolator.pluralExpression.mostRecentCall.args[2]
      expect(pluralExpression.word).toEqual("word")
      expect(pluralExpression.suffixes).toEqual(["s"])
      expect(pluralExpression.fn(2)).toEqual("words")
      expect(argument.argName).toEqual("y")

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

describe "granula.canTranslate", ->

  beforeEach ->
    granula = granulaCtor()

  it "shall return true if there is a translation", ->
    granula.load {en: {key1: "hello"}}
    expect(granula.canTranslate("en", "key1")).toBeTruthy()

  it "shall return false if there is no translation for specified key", ->
    granula.load {en: {key1: "hello"}}
    expect(granula.canTranslate("en", "key2")).toBeFalsy()

  it "shall return false if there is translation but not for specified language", ->
    granula.load {en: {key1: "hello"}}
    expect(granula.canTranslate("ru", "key1")).toBeFalsy()

describe "granula.canTranslateTo", ->

  beforeEach ->
    granula = granulaCtor()

  it "shall return true if language is defined", ->
    granula.load {en: {}}
    expect(granula.canTranslateTo("en")).toBeTruthy()

  it "shall return true if language is not defined", ->
    expect(granula.canTranslateTo("en")).toBeFalsy()
