granula = require('../granula/granula')
processor = require('./processor')
{htmlDocument} = require('./documents')
fs = require('fs')
wrench = require('wrench')

module.exports =
  processFiles: (folderPath, options, cb) ->

  processHtmlFile: (filePath, options, cb) ->
    htmlText = fs.readFileSync(filePath, options.encoding ? "utf-8")
    outputStruct =
      lang: {}
      errors: []
      warnings: []

    processor().processHtml outputStruct.lang, htmlDocument(htmlText), options, {
      addError: (e) -> outputStruct.errors.push(e)
      addWarning: (w) -> outputStruct.warnings.push(w)
    }

    cb(outputStruct)

module.exports.processHtmlFile "C:\\Programming\\Projects\\granula\\examples\\todomvc\\index.html", {
  onlyMarked: false
}, (struct) ->
  console.log JSON.stringify(struct, null, 4)
