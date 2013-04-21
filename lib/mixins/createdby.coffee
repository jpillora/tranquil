util = require "../util"

module.exports = (resource) ->
  
  util.mixin resource.opts, {
    schema:
      createdBy:
        type: mongoose.Schema.ObjectId
  }