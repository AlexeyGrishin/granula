

describe "granula filter", ->
  $interpolate = null
  $scope = null

  beforeEach ->
    module("granula")
    inject (_$interpolate_) ->
      $interpolate = _$interpolate_
      $scope = {}

  it "shall translate specified word", ->
    expect($interpolate("{{'hello' | grTranslate}}")($scope)).toEqual('привет')