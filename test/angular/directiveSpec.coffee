$scope = null
dom = (template, scopeArgs) ->
  for key,val of scopeArgs
    $scope[key] = val
  d = template($scope)
  $scope.$digest()
  d

describe "grKey directive", ->
  html = ""
  service = null

  beforeEach ->
    module("granula")
    inject (_$compile_, _$rootScope_, grService) ->
      $scope = _$rootScope_.$new()
      service = grService
      grService.save "key1", "У нас {{1}} тест(,а,ов)", "ru"
      html = (expr = 'tests') -> _$compile_("<p gr-key='key1'>We have {{#{expr}}} test(s)</p>")

  describe "shall parse and apply plural expressions", ->

    it "when number is 1", ->
      expect(dom(html(), tests:1).text()).toEqual("We have 1 test")

    it "when number is 2", ->
      expect(dom(html(), tests:2).text()).toEqual("We have 2 tests")

    it "when variable is angular expression", ->
      expect(dom(html("tests + tests"), tests:1).text()).toEqual("We have 2 tests")

    it "when variable is angular expression with grPluralize directive - it shall be moved out", ->
      expect(dom(html("tests | grPluralize:'test(s)'"), tests:1).text()).toEqual("We have test test")

  it "shall use text itself as key if key is not defined", ->
    inject ($compile, grService) ->
      grService.save "Next", "Далее", "ru"
      grService.setLanguage "ru"
      expect(dom($compile("<button gr-key>Next</button>")).text()).toEqual("Далее")

  it "shall use text itself as key if key is not defined even text contains bindings", ->
    inject ($compile, grService) ->
      grService.save "Next {{step}}", "Далее {{step}}", "ru"
      grService.setLanguage "ru"
      expect(dom($compile("<button gr-key>Next {{step}}</button>"), step: "5").text()).toEqual("Далее 5")


  describe "for dynamic key", ->
    dynamicKey = null
    beforeEach ->
      inject (_$compile_, _$rootScope_, grService) ->
        grService.save "key2", "Text for key2", "en"
        grService.save "key3", "Text for key3", "en"
        grService.save "key2", "Текст для key2", "ru"
        grService.save "key3", "Текст для key3", "ru"
        dynamicKey = -> _$compile_("<p gr-key='key{{key}}'>Never showing text</p>")

    it "shall never render original text", ->
      expect(dom(dynamicKey(), key: 2).text()).not.toEqual("Never showing text")

    it "shall show empty text if there is no text for key", ->
      expect(dom(dynamicKey(), key: 5).text()).toEqual("")

    it "shall change the text when key is changed", ->
      dom1 = dom(dynamicKey(), key: 2)
      expect(dom1.text()).toEqual("Text for key2")
      $scope.$apply -> $scope.key = 3
      expect(dom1.text()).toEqual("Text for key3")


  it "shall react on language change and get translation by defined key", ->
    dom1 = dom(html(), tests:2)
    service.setLanguage "ru"
    $scope.$digest()
    expect(dom1.text()).toEqual("У нас 2 теста")


  it "shall show in valid language if it is initially defined", ->
    service.setLanguage "ru"
    dom1 = dom(html(), tests:5)
    expect(dom1.text()).toEqual("У нас 5 тестов")


  describe "within ng-repeat", ->
    noInterpolation = null
    interpolation = null
    beforeEach ->
      inject (_$compile_) ->
        noInterpolation = -> _$compile_ """
                             <div>
                             <span ng-repeat='b in bs' gr-key='key1'>Test</span>
                             </div>
                             """
        interpolation = -> _$compile_ """
                                        <div>
                                        <span ng-repeat='b in bs' gr-key='key2'>{{b}} test(s)</span>
                                        </div>
                                        """

      service.save "key1", "Translated", "ru"
      service.save "key2", "{{1}} тест(,а,ов)", "ru"


    it "shall translate each text without interpolation", ->
      dom1 = dom(noInterpolation(), bs: [1,2])
      service.setLanguage "ru"
      $scope.$digest()
      spans = dom1.find("span")
      expect(spans.eq(0).text()).toEqual("Translated")
      expect(spans.eq(1).text()).toEqual("Translated")

    it "shall translate each etxt with interpolation", ->
      dom1 = dom(interpolation(), bs: [1,2])
      service.setLanguage "ru"
      $scope.$digest()
      spans = dom1.find("span")
      expect(spans.eq(0).text()).toEqual("1 тест")
      expect(spans.eq(1).text()).toEqual("2 теста")



describe "gr-attrs directive", ->

  html = null
  $scope = null
  service = null

  beforeEach ->
    module("granula")
    inject (grService, $compile, $rootScope) ->
      service = grService
      $scope = $rootScope.$new()
      grService.save "key1", "Привет {{1}}", "ru"
      html = (key) ->
        $compile(
          """
          <span gr-attrs="title" #{if key then 'gr-key-title="' +key + '"' else ''} title="Hello {{name}}"></span>
          """
        )

  it "shall translate specified attributes", ->
    service.setLanguage "ru"
    expect(dom(html("key1"), name: "Bob").attr("title")).toEqual("Привет Bob")

  it "shall translate specified attributes for dynamic keys", ->
    service.setLanguage "ru"
    service.save "key1", "Holla {{name}}", "en"
    expect(dom(html("{{keyVal + '1'}}"), {name: "Bob", keyVal: "key"}).attr("title")).toEqual("Привет Bob")

  it "shall use attribute value as key if it is not specified", ->
    service.setLanguage "ru"
    service.save "Hello {{name}}", "Привет {{name}}", "ru"
    expect(dom(html(), name: "Bob").attr("title")).toEqual("Привет Bob")



  it "shall work for several attributes and with gr-key directive", ->
    inject ($compile) ->
      html = (keyTitle, keyAlt, keyText) -> $compile(
        """
        <button gr-attrs="title,alt" gr-key-title="#{keyTitle}" gr-key-alt="#{keyAlt}" gr-key="#{keyText}"
          title="Click to continue" alt="One of {{buttons}} button(s)">OK</button>
        """
      )

    service.save "key1", "Нажмите для продолжения", "ru"
    service.save "key2", "Одна из {{buttons}} кнопка(ок,ок)", "ru"
    service.save "key3", "Да будет так", "ru"

    service.setLanguage "ru"
    dom1 = dom(html("key1", "key2", "key3"), buttons: 3)
    expect(dom1.text()).toEqual("Да будет так")
    expect(dom1.attr("title")).toEqual("Нажмите для продолжения")
    expect(dom1.attr("alt")).toEqual("Одна из 3 кнопок")


describe "gr-lang directive", ->

  service = null
  $scope = null
  html = null
  beforeEach ->
    module("granula")
    inject ($rootScope, grService, $compile) ->
      service = grService
      $scope = $rootScope.$new()
      html = (original, current) ->
        $compile(
          """
          <div gr-lang="#{current}" gr-lang-of-text="#{original}">
          <span gr-key="key1">Warning!</span>
          </div>
          """
        )
      service.save "key1", "Внимание!", "ru"
      service.save "key1", "Увага!", "ua"
      service.save "key1", "Important!", "en"


  it "shall define original language (language of text on page)", ->
    dom1 = dom(html("ru", "en"), {})
    expect(service.originalLanguage).toEqual("ru")
    expect(service.language).toEqual("en")
    expect(dom1.text().trim()).toEqual("Important!")

  it "shall define current language", ->
    dom1 = dom(html("en", "ru"), {})
    expect(service.originalLanguage).toEqual("en")
    expect(service.language).toEqual("ru")
    expect(dom1.text().trim()).toEqual("Внимание!")

  it "shall change language on page", ->
    dom1 = dom(html("en", "{{lang}}"), {lang: "en"})
    expect(service.language).toEqual("en")
    expect(dom1.text().trim()).toEqual("Warning!")
    $scope.lang = "ua"
    $scope.$digest()
    expect(dom1.text().trim()).toEqual("Увага!")


describe 'gr-lang attribute for script', ->

  beforeEach ->
    module('granula')

  it 'shall load language definitions from script contents', ->
    dom = """
          <script gr-lang='it' type='granula/lang'>
          {"key1": "value1"}
          </script>
          """
    inject ($compile, grService) ->
      $compile(dom)
      expect(grService.canTranslate("key1", "it")).toBeTruthy()

  it 'shall asynchronously load language definitions from source when switching', ->
    dom = """
            <script gr-lang='it' src='it.json' type='granula/lang'></script>
          """
    inject ($compile, grService, $rootScope, $httpBackend) ->
      onStartChange = jasmine.createSpy()
      onChange = jasmine.createSpy()
      $rootScope.$on 'gr-lang-load', onStartChange
      $rootScope.$on 'gr-lang-changed', onChange

      $compile(dom)
      $httpBackend.verifyNoOutstandingRequest()
      expect(grService.canTranslate("key1", "it")).toBeFalsy()

      $httpBackend.expectGET('it.json').respond({"key1": "value"})

      grService.setLanguage("it")
      expect(onStartChange).toHaveBeenCalled()
      expect(onChange).not.toHaveBeenCalled()

      $httpBackend.flush()
      expect(onChange).toHaveBeenCalled()
      expect(grService.canTranslate("key1", "it")).toBeTruthy()

      $httpBackend.verifyNoOutstandingExpectation()

  it "shall load several files and do not throw errors until data is loaded", ->
    dom = """
          <div>
            <script gr-lang='en' src='en1.json' type='granula/lang'></script>
            <script gr-lang='en' src='en2.json' type='granula/lang'></script>
            <div gr-lang='en'>
              <span id='s1' gr-key="t1"></span>
              <p id='s2' gr-key="t2"></p>
            </div>
          </div>
          """
    inject ($compile, grService, $rootScope, $httpBackend) ->
      $httpBackend.expectGET('en1.json').respond({"t1": "value1"})
      $httpBackend.expectGET('en2.json').respond({"t2": "value2"})
      scope = $rootScope.$new()
      html = $compile(dom)(scope)
      $httpBackend.flush()
      scope.$digest()
      expect(html.find('span').text()).toEqual("value1")
      expect(html.find('p').text()).toEqual("value2")

  it 'shall not produce errors when language switched to another one during load', ->
    dom = """
          <div>
            <script gr-lang='it' src='it.json' type='granula/lang'></script>
            <div gr-lang-of-text='it' gr-lang='it' gr-key='key1'></div>
          </div>
          """
    inject ($compile, grService, $rootScope, $httpBackend) ->
      onStartChange = jasmine.createSpy()
      onChange = jasmine.createSpy()
      $rootScope.$on 'gr-lang-load', onStartChange

      $rootScope.$on 'gr-lang-changed', onChange

      $httpBackend.expectGET('it.json').respond({"key1": "value"})
      html = $compile(dom)($rootScope.$new())
      expect(onStartChange).toHaveBeenCalled()
      expect(onChange).not.toHaveBeenCalled()
      grService.setLanguage('it')
      expect(onChange).not.toHaveBeenCalled()
      $httpBackend.flush()
      expect(onChange).toHaveBeenCalled()
      $httpBackend.verifyNoOutstandingExpectation()
      $httpBackend.verifyNoOutstandingRequest()
      expect(html.find('div').text()).toEqual('value')

