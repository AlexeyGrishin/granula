#got from http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html?id=l10n/pluralforms
pluralizationForms = [
  {
    plural:(n) -> `(n > 1) ? 1 : 0`;
    languages: ['ach','ak','am','arn','br','fil','fr','gun','ln','mfe','mg','mi','oc','pt_BR','tg','ti','tr','uz','wa','zh']
  },
  {
    plural:(n) -> `(n != 1) ? 1 : 0`;
    languages: ['af','an','ast','az','bg','bn','brx','ca','da','de','doi','el','en','eo','es','es_AR','et','eu','ff','fi','fo','fur','fy','gl','gu','ha','he','hi','hne','hy','hu','ia','it','kn','ku','lb','mai','ml','mn','mni','mr','nah','nap','nb','ne','nl','se','nn','no','nso','or','ps','pa','pap','pms','pt','rm','rw','sat','sco','sd','si','so','son','sq','sw','sv','ta','te','tk','ur','yo']
  },
  {
    plural:(n) -> `(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5)`;
    languages: ['ar']
  },
  {
    plural:(n) -> 0;
    languages: ['ay','bo','cgg','dz','fa','id','ja','jbo','ka','kk','km','ko','ky','lo','ms','my','sah','su','th','tt','ug','vi','wo','zh']
  },
  {
    plural:(n) -> `(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)`;
    languages: ['be','bs','hr','ru','sr','uk']
  },
  {
    plural:(n) -> `(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2`;
    languages: ['cs','sk']
  },
  {
    plural:(n) -> `n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2`;
    languages: ['csb']
  },
  {
    plural:(n) -> `(n==1) ? 0 : (n==2) ? 1 : (n != 8 && n != 11) ? 2 : 3`;
    languages: ['cy']
  },
  {
    plural:(n) -> `n==1 ? 0 : n==2 ? 1 : n<7 ? 2 : n<11 ? 3 : 4`;
    languages: ['ga']
  },
  {
    plural:(n) -> `(n==1 || n==11) ? 0 : (n==2 || n==12) ? 1 : (n > 2 && n < 20) ? 2 : 3`;
    languages: ['gd']
  },
  {
    plural:(n) -> `(n%10!=1 || n%100==11) ? 1 : 0`;
    languages: ['is']
  },
  {
    plural:(n) -> `(n != 0) ? 1 : 0`;
    languages: ['jv']
  },
  {
    plural:(n) ->  `(n==1) ? 0 : (n==2) ? 1 : (n == 3) ? 2 : 3`;
    languages: ['kw']
  },
  {
    plural:(n) -> `(n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2)`;
    languages: ['lt']
  },
  {
    plural:(n) -> `(n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2)`;
    languages: ['lv']
  },
  {
    plural:(n) ->  `n==1 || n%10==1 ? 0 : 1`;
    languages: ['mk']
  },
  {
    plural:(n) -> `(n==0 ? 0 : n==1 ? 1 : 2)`;
    languages: ['mnk']
  },
  {
    plural:(n) -> `(n==1 ? 0 : n==0 || ( n%100>1 && n%100<11) ? 1 : (n%100>10 && n%100<20 ) ? 2 : 3)`;
    languages: ['mt']
  },
  {
    plural:(n) -> `(n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)`;
    languages: ['pl']
  },
  {
    plural:(n) -> `(n==1 ? 0 : (n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2)`;
    languages: ['ro']
  },
  {
    plural:(n) -> `(n%100==1 ? 1 : n%100==2 ? 2 : n%100==3 || n%100==4 ? 3 : 0)`;
    languages: ['sl']
  }
]

normalizationForms =
  en: (word, suffixes) ->
    word: word
    suffixes: switch suffixes.length
      when 1 then ["", suffixes[0]]
      else suffixes
  ru: (word, suffixes) ->
    switch suffixes.length
      when 1 then {word, suffixes: ["", suffixes[0], ""]}
      when 2
        form2Suffix = suffixes[1]
        singularSuffix = word.slice(-form2Suffix.length)
        {word: word.slice(0, -singularSuffix.length), suffixes: [singularSuffix].concat(suffixes)}
      else
        {word, suffixes}

module.exports = ->

  pluralizationRules = {}
  for form in pluralizationForms
    for lang in form.languages
      pluralizationRules[lang] = pluralize: form.plural, normalize: normalizationForms[lang]

  _get: (language, options = {useEnglishAsDefault: true}) ->
    if not pluralizationRules[language] and options.useEnglishAsDefault
      language = "en"
    pluralizationRules[language]

  getPluralizeForm: (language, value, options) ->
    @_get(language, options).pluralize value

  normalizeForms: (language, word, suffixes, options) ->
    (@_get(language, options).normalize ? @_doNotNormalize)(word, suffixes)

  updatePluralization: (language, pluralizeFn, normalizeFn) ->
    pluralizationRules[language] = pluralize: pluralizeFn, normalize: normalizeFn

  _doNotNormalize: (word, suffixes) -> {word, suffixes}

  preparePluralizationFn: (language, word, suffixes, options) ->
    res = @normalizeForms language, word, suffixes, options
    (val) =>
      console.log @getPluralizeForm(language, val, options)
      res.word + res.suffixes[@getPluralizeForm(language, val, options)]

  getLanguages: -> Object.keys(pluralizationRules)

  getAll: -> pluralizationRules




