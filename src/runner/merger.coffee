_ = require('underscore')

ADDED_KEY =   "-------------------added"
DELETED_KEY = "-----------------deleted"

module.exports =
  merge: (oldJson, newJson, options) ->
    options = _.defaults(options, {translateMe: "[^_^]"})
    previouslyDeleted = oldJson[DELETED_KEY]
    oldJson = _.omit oldJson, DELETED_KEY, ADDED_KEY
    oldKeys = _.keys(oldJson)
    newKeys = _.keys(newJson)
    existent = _.intersection(oldKeys, newKeys)
    disappeared = _.difference(oldKeys, newKeys)
    appeared = _.difference(newKeys, oldKeys)

    newObj = {}
    newObj[ADDED_KEY] = "#{new Date().toString()}" if appeared.length > 0
    _.extend newObj, _.object(appeared.map (k) -> [k, "#{options.translateMe} #{newJson[k]}"])
    newObj[DELETED_KEY] = _.extend({}, _.object(disappeared.map (k) -> [k, oldJson[k]]), previouslyDeleted)
    _.extend newObj, _.object(existent.map (k) -> [k, oldJson[k]])
    newObj