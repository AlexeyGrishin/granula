

describe "grPluralize filter", ->
  $interpolate = null
  $scope = null
  fn = null

  beforeEach ->
    module("granula")
    inject (_$interpolate_) ->
      $interpolate = _$interpolate_
      $scope = {}
    fn = $interpolate("{{amount | grPluralize:'word(s)'}}")

  it "shall pluralize specified expression when value = 1", ->
    expect(fn(amount:1)).toEqual("word")

  it "shall pluralize specified expression when value = 2", ->
    expect(fn(amount:2)).toEqual("words")