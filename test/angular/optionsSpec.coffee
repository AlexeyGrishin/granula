describe "options", ->
  service = null

  describe "textAsKey", ->

    doCompile = ($compile) ->
      $compile(
        """
        <p>Are you OK?</p>
        <button gr-key="cancel">OK</button>
        <button gr-key>Not at all</button>
        """
      )
    doConfig = (config) ->
      angular.mock.module("granula")
      angular.mock.module((grServiceProvider) -> grServiceProvider.config(config); return undefined)

    describe "with value 'always'", ->


      beforeEach -> doConfig {textAsKey: "always"}

      it "shall get keys from text if both specified", ->
        inject ($compile, grService) ->
          doCompile($compile)
          expect(grService.canTranslate("cancel")).toBeFalsy()
          expect(grService.canTranslate("OK")).toBeTruthy()

      it "shall get keys from text if key is empty", ->
        inject ($compile, grService) ->
          doCompile($compile)
          expect(grService.canTranslate("Not at all")).toBeTruthy()

      it "shall not get key from element without gr-key", ->
        inject ($compile, grService) ->
          doCompile($compile)
          expect(grService.canTranslate("Are you OK?")).toBeFalsy()

    describe "with value 'never'", ->

      beforeEach -> doConfig {textAsKey: "never"}

      it "shall get key from attribute if it is specified", ->
        inject ($compile, grService) ->
          $compile("""<button gr-key="cancel">OK</button>""")
          expect(grService.canTranslate("cancel")).toBeTruthy()
          expect(grService.canTranslate("OK")).toBeFalsy()

      it "shall generate an error if attribute is not specified well", ->
        inject ($compile, grService) ->
          expect(->doCompile($compile)).toThrow()
          expect(grService.canTranslate("Not at all")).toBeFalsy()
