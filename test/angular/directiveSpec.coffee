describe "grKey directive", ->
  $scope = null
  html = ""

  beforeEach ->
    module("granula")
    inject (_$compile_, _$rootScope_, grService) ->
      $scope = _$rootScope_.$new()
      grService.save "ru", "key1", "У нас {{1}} тест(,а,ов)"
      html = _$compile_("<p gr-key='key1'>We have {{tests}} test(s)</p>")

  dom = (template, scopeArgs) ->
    for key,val of scopeArgs
      $scope[key] = val
    d = template($scope)
    $scope.$digest()
    d


  describe "shall parse and apply plural expressions", ->

    it "when number is 1", ->
      expect(dom(html, tests:1).text()).toEqual("We have 1 test")

    it "when number is 2", ->
      expect(dom(html, tests:2).text()).toEqual("We have 2 tests")
