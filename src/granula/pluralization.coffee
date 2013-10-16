normalize = (f1) ->
  "with": (f2) ->
    pluralize: f1
    normalize: f2


#TODO: add other languages

module.exports = ->

  pluralizationForms =
    en: normalize((num)->
      if num == 1 then 0 else 1
    ).with (word, suffixes) ->
      word: word
      suffixes: switch suffixes.length
        when 1 then ["", suffixes[0]]
        else suffixes

    ru: normalize((num) ->
      if num in [10..20]
        return 2
      else if num % 10 == 1
        return 0
      else if num % 10 in [2..4]
        return 1
      return 2
    ).with (word, suffixes) ->
      switch suffixes.length
        when 1 then {word, suffixes: ["", suffixes[0], ""]}
        when 2
          form2Suffix = suffixes[1]
          singularSuffix = word.slice(-form2Suffix.length)
          {word: word.slice(0, -singularSuffix.length), suffixes: [singularSuffix].concat(suffixes)}
        else
          {word, suffixes}


  _get: (language, options = {useEnglishAsDefault: true}) ->
    if not pluralizationForms[language] and options.useEnglishAsDefault
      language = "en"
    pluralizationForms[language]

  getPluralizeForm: (language, value, options) ->
    @_get(language, options).pluralize value

  normalizeForms: (language, word, suffixes, options) ->
    (@_get(language, options).normalize ? @_doNotNormalize)(word, suffixes)

  updatePluralization: (language, pluralizeFn, normalizeFn) ->
    pluralizationForms[language] = normalize(pluralizeFn).with(normalizeFn)

  _doNotNormalize: (word, suffixes) -> {word, suffixes}

  preparePluralizationFn: (language, word, suffixes, options) ->
    res = @normalizeForms language, word, suffixes, options
    (val) =>
      res.word + res.suffixes[@getPluralizeForm(language, val, options)]

  getLanguages: -> Object.keys(pluralizationForms)

  getAll: -> pluralizationForms



