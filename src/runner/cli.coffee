fs = require('fs')
runner = require('./runner')
{argv} = require('optimist')
  .usage("Usage: granula [-s src-folder] [-o output-folder] [-config file] <languages-list>")

configuration = {}
if argv.config
  configuration = JSON.parse(fs.readFileSync("./" + argv.config))
else if fs.existsSync("./Granulafile")
  configuration = JSON.parse(fs.readFileSync("./Granulafile"))
else
  configuration = {
    src: argv.s,
    out: argv.o,
    languages: argv._?[0]
  }

runner.processFiles configuration, (error, res) ->
  console.error(error) if error
  console.log(res ? "Done!") if not error
  process.exit(if error then 4 else 0)

