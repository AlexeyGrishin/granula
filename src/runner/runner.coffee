_ = require('underscore')
granula = require('../granula/granula')
processor = require('./processor')
{htmlDocument} = require('./documents')
fs = require('fs')
wrench = require('wrench')
merger = require('./merger')
path = require('path')

module.exports =
  ###
  # options =
  #   src: string = '.'                   - directory to scan
  #   fileTypes: comma-separated string   - which files to process ('html', 'js')
  #   out: string = './lang'              - where to search/store language files
  #   languages: comma-separated tring    - language files to create
  #   mapping:
  #     onlyMarked: boolean = true        - if true then only elements marked with gr-key will be processed
  #     textAsKey: string = "nokey"       - "always" - key is obtained from gr-key, error if empty.
  #                                         "never" - key is always obtained from text
  #                                         "nokey" - key obtains from gr-key if presents, from text otherwise
  #     wordsLimitForKey: int = 10        - how many first words will be taken for key
  #     replaceSpaces: false or string = false  - shall spaces be replaced or not
  #     attrsToTranslate: comma-separated string - which attributes shall be translated. "title,alt,placeholder" by default
  #     generateSettingsFile: false or file name - generate file with these settings under 'out' directory
  ###
  processFiles: (options, cb) ->
    options = @_options(options)
    processingResult = {}
    wrench.readdirRecursive options.src, (error, files) =>
      return cb(error) if error
      return @_merge(options, processingResult, cb) if error == files == null
      htmlFiles = files.filter (f) ->f.toLowerCase().slice(-5) == '.html'
      htmlFiles.forEach (file) =>
        console.log "Processing #{file}"
        @processHtmlFile processingResult, path.join(options.src, file), options

  _try: (action) ->
    "catch": (react) ->
      try
        action()
      catch e
        react()

  _merge: (options, {errors, warnings, lang}, cb) ->
    if errors.length > 0
      errors.forEach (e) -> console.error "Error: #{e}"
      return cb("Processing interrupted due to errors")
    warnings.forEach (w) -> console.info "  -- Warning: #{w}"
    options.languages.forEach (language) =>
      langFilePath = path.join(options.out, language + '.json')
      oldJson = @_try(->JSON.parse(fs.readFileSync(langFilePath))).catch(->{})
      newJson = merger.merge(oldJson, lang, options)
      fs.writeFileSync(langFilePath, JSON.stringify(newJson, null, 4))
      console.log "Created #{langFilePath}"
    @_writeSettings(options, lang, cb) ->

  _writeSettings: (options, lang, cb) ->
    if options.mapping.generateSettingsFile
      settingsFilePath = path.join(options.out, options.mapping.generateSettingsFile)
      settings = @_settingsTemplate.replace(/__OPTIONS__/, JSON.stringify(_.omit(options.mapping, 'generateSettingsFile')))
      fs.writeFileSync(settingsFilePath, settings)
      console.log "Created #{settingsFilePath}"
    cb(null)

  _settingsTemplate:
    """
    angular.module('granula').config(["grServiceProvider", function(grServiceProvider) {
      grServiceProvider.config(__OPTIONS__)
    }])
    """

  _options: (options ) ->

    mapping = options.mapping ? {}
    delete options.mapping

    options = _.defaults(options, {
      src: '.',
      fileTypes: 'html',
      out: './lang',
      languages: ""
    })

    options.mapping = _.defaults(mapping, {
      onlyMarked: true,
      textAsKey: "nokey",
      wordsLimitForKey: 10,
      replaceSpaces: false,
      attrsToTranslate: "title,alt,placeholder",
      generateSettingsFile: "settings.js"
    })

    csToList = (str) ->
      return [] if _.isEmpty(str)
      str.split(',')

    options.fileTypes = csToList options.fileTypes
    options.languages = csToList options.languages
    options.mapping.attrsToTranslate = csToList options.mapping.attrsToTranslate

    validateEnum = (name, value, possible) ->
      if _.isArray(value)
        if _.difference(value, possible).length > 0
          throw new Error("Option '#{name}' shall contain only following values: #{possible.join(', ')}")
      else
        if _.indexOf(possible, value) == -1
          throw new Error("Option '#{name}' shall be one of the following values: #{possible.join(', ')}")

    validateInteger = (name, value) ->
      throw new Error("Option '#{name}' shall be number ") if _.isNaN(parseInt(value))

    validateEnum("fileTypes", options.fileTypes, ["html"])
    validateEnum("onlyMarked", options.mapping.onlyMarked, [true, false])
    validateEnum("textAsKey", options.mapping.textAsKey, ["nokey", "always", "never"])
    validateInteger("wordsLimitForKey", options.mapping.wordsLimitForKey)

    if options.languages.length == 0
      throw new Error("At least one language shall be provided")
    options


  processHtmlFile: (outputStruct, filePath, options) ->
    htmlText = fs.readFileSync(filePath, options.encoding ? "utf-8")
    outputStruct = _.defaults outputStruct,
      lang: {}
      errors: []
      warnings: []

    processor().processHtml outputStruct.lang, htmlDocument(htmlText), options.mapping, {
      addError: (e) -> outputStruct.errors.push(e)
      addWarning: (w) -> outputStruct.warnings.push(w)
    }
