# attributes - array of values or array of 1 struct
context = (attributes, interpolator) ->
  ctx = {
    attrs: {}
  }
  if attributes.length is 1 and typeof(attributes[0]) is 'object'
    for key, value of attributes[0]
      ctx.attrs[key] = value
  else
    for attr, idx in attributes
      ctx.attrs[idx+1] = attr
  noop = ->
  ctx.interpolate = (method, data...) ->
    (interpolator[method] ? noop)(ctx, data...)
  ctx.begin = -> interpolator.begin?(ctx)
  ctx.end = (result) -> interpolator.end?(ctx, result)
  ctx.apply = (fn) ->
    ctx.begin()
    res = fn(ctx)
    ctx.end(res) ? res
  ctx

module.exports = {context}