describe "grService service", ->
  service = null

  beforeEach ->
    module("granula")
    inject (grService) ->
      service = grService

