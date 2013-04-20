# build tranq actions
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
  constructor: (@name, @opts = {}, @tranq) ->

    _.bindAll @

    unless _.isPlainObject @opts
      @error "Options must be a plain object"

    _.defaults @opts, _.cloneDeep @defaults

    #no schema
    unless @opts.schema
      #auto lazy schema on non-user objs
      unless @opts.isUser
        @opts.schemaOpts.strict = false
      @opts.schema = {}

    @routeName = @name.toLowerCase()
    @children = {}

  initialize: ->
    @checkOpts()
    @checkSchema()
    @defineSchema()
    @defineSchemaMiddleware()
    @defineRoute()
    @log "ready"
    
  #CONFIG
  checkOpts: ->
    if @opts.isUser
      userify @
      @tranq.UserResource = @

    if @tranq.opts.timestamps
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
        other = @tranq.resources[val]
        if other and other.Schema
          @linkResource isArray, key, other
        else
          @error "could NOT find: #{val}"
      
      if _.isPlainObject(val) and _.isArray(val.validate)
        val.validate = _.map val.validate, (str) =>
          return str if typeof str isnt 'string'
          validator = @tranq.validators[str]
          @error "Missing validator: #{str}" unless validator
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
      Extend = @tranq.resources[@opts.extend]
      @error "#Cannot extend. Missing schema: #{@opts.extend}" unless Extend
      @Schema =  Extend.extend @opts.schema, @opts.schemaOpts
    else
      @Schema = new mongoose.Schema @opts.schema, @opts.schemaOpts
    
    #build mongoose model
    @Model = @tranq.db.model @name, @Schema
    #back ref
    @Schema.resource = @

  defineSchemaMiddleware: ->
    set = (time, type, fn) =>
      if _.isFunction fn
        @Schema[time](type, fn)
        @log "middleware: #{time} #{type}"
      else
        @log fn
        @error "Invalid middleware #{time} #{type}"
    
    middleware = @opts.middleware

    for time, types of middleware
      for type, fns of types
        if _.isArray fns
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

  log: ->
    a = Array.prototype.slice.call arguments
    a.unshift @.toString()
    console.log.apply console, a

  error: (s) ->
    throw "#{@} #{s}"

  #helpers
  toString: ->
    "Resource: #{@name}:"

module.exports = Resource

