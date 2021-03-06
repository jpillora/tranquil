util = require "../util"

module.exports = (resource) ->

  #add user into into schema
  util.mixin resource.opts, {
    schema:
      createdAt:
        type: Date
        required: true

      updatedAt:
        type: Date
        required: true

    databaseMiddleware:
      pre:
        validate: [(next) ->
          @updatedAt = new Date()
          @createdAt = @updatedAt unless @createdAt
          next()
        ]

  }