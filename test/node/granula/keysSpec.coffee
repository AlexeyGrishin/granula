keys = require('../../../src/granula/keys')

describe 'key extractor', ->

  describe "when option is 'never'", ->
    it "shall get key attribute even there is a text", ->
      expect(keys.toKey("key", "text", {textAsKey: 'never'})).toEqual("key")

    it "shall throw error on undefined key", ->
      expect(->keys.toKey(undefined, "text", {textAsKey: 'never'})).toThrow()

    it "shall throw error on null key", ->
      expect(->keys.toKey(null, "text", {textAsKey: 'never'})).toThrow()

    it "shall throw error on empty key", ->
      expect(->keys.toKey("", "text", {textAsKey: 'never'})).toThrow()

  describe "when option is 'always'", ->

    it "shall get text as key when key is defined", ->
      expect(keys.toKey("key", "text", {textAsKey: 'always'})).toEqual("text")

    it "shall get text as key when key is not defined", ->
      expect(keys.toKey(undefined, "text", {textAsKey: 'always'})).toEqual("text")

    it "shall get text as key using first N words if specified in options", ->
      expect(keys.toKey("key", "text in four words", {textAsKey: 'always', wordsLimitForKey: 2})).toEqual("text in")

    it "shall get text as key replacing spaces if specified in options", ->
      expect(keys.toKey("key", "text in four words", {textAsKey: 'always', replaceSpaces: "!"})).toEqual("text!in!four!words")

  describe "when option is 'nokey'", ->

    it "shall get attribute as key when key is defined", ->
      expect(keys.toKey("key", "text", {textAsKey: 'nokey'})).toEqual("key")

    it "shall get text as key when key is not defined", ->
      expect(keys.toKey(undefined, "text", {textAsKey: 'nokey'})).toEqual("text")

    it "shall get text as key when key is empty", ->
      expect(keys.toKey("", "text", {textAsKey: 'nokey'})).toEqual("text")
