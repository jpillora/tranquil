# build rest actions
_ = require 'lodash'
mongoose = require 'mongoose'
require './schema-extend'
userify = require './userify'
timestampify = require './timestampify'
Routes = require './routes'

#plugin variabless
unimplemented = (req, res) -> res.status 501

#define
class Resource
  
  defaults:
    idField: '_id'
    schemaOpts:
      strict: true
    middleware: {}

  #ENTRY
  constructor: (@name, @opts = {}, @rest) ->

    _.bindAll @

    unless _.isPlainObject @opts
      throw "Options must be a plain object"

    @opts.schema = {} unless @opts.schema

    _.defaults @opts, _.cloneDeep @defaults

    @routeName = @name.toLowerCase()
    @children = {}

  initialize: ->
    @checkOpts()
    @checkSchema()
    @defineSchema()
    @defineSchemaMiddleware()
    @defineRoute()
    console.log @name, "resource ready"
    
  #CONFIG
  checkOpts: ->
    if @opts.isUser
      userify @
      @rest.UserResource = @

    if @rest.opts.timestamps
      timestampify @

  #SCHEMA
  checkSchema: ->

    #extract children
    for key, val of @opts.schema

      #array check
      isArray = _.isArray(val) and val.length is 1
      val = val[0] if isArray

      #link resource
      if typeof val is 'string'
        other = @rest.resources[val]
        if other and other.Schema
          @linkResource isArray, key, other
        else
          throw "#{@name} could NOT find: #{val}"
      
      if _.isPlainObject(val) and _.isArray(val.validate)
        val.validate = _.map val.validate, (str) =>
          return str if typeof str isnt 'string'
          validator = @rest.validators[str]
          throw "Missing validator: #{str}" unless validator
          return validator

  linkResource: (isArray, field, other) ->

    #single
    unless isArray
      @opts.schema[field] = mongoose.Schema.ObjectId
      return

    #array
    @opts.schema[field] = [mongoose.Schema.ObjectId]
    @children[field] = other

  defineSchema: ->

    #build mongoose schema
    if typeof @opts.extend is 'string'
      Extend = @rest.resources[@opts.extend]
      throw "Missing #{@opts.extend}" unless Extend
      @Schema =  Extend.extend @opts.schema, @opts.schemaOpts
    else
      @Schema = new mongoose.Schema @opts.schema, @opts.schemaOpts
    
    #build mongoose model
    @Model = @rest.db.model @name, @Schema
    #back ref
    @Schema.resource = @

  defineSchemaMiddleware: ->
    set = (time, type, fn) =>
      t = typeof fn
      if t is 'function'
        @Schema[time](type, fn)
        console.log "set middleware: #{time} #{type}"
      else
        console.log fn
        throw "Invalid middleware #{time} #{type} type: #{t}"
    
    middleware = @opts.middleware

    for time, types of middleware
      for type, fns of types
        if typeof fns is 'array'
          for fn in fns
            set time, type, fn
        else
          set time, type, fns
    null

  #ROUTES
  defineRoute: (parent) ->
    #define this resource's routes
    routes = new Routes @, parent    
    #define child routes ontop
    for n, child of @children
      child.defineRoute routes


  #helpers
  toString: -> @name + ": "

module.exports = Resource

