stringInterpolator = ->
  begin: (context) ->
  string: (context, str) -> str
  argument: (context, {argName}) ->
    val = context.attrs[argName]
    if typeof val is 'function' then val() else val
  pluralExpression: (context, {fn}, argument) ->
    fn(argument.apply(context))
  end: (context) ->

module.exports = {stringInterpolator}