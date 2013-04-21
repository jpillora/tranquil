_ = require "lodash"

mixinClash = (a, b) ->
  # console.log  "CLASH", a, b
  return a.concat(b) if _.isArray a
  # return b.concat(a) if _.isArray b
  `undefined`

module.exports = {
  mixin: ->
    args = _.toArray(arguments)
    # args.unshift {}
    args.push mixinClash
    _.merge.apply @, args
    args[0]
}





