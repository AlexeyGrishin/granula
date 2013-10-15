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

  it 'shall asynchronously load language definitions from source when sцitching', ->
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


