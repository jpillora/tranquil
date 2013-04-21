# build tranq actions
_ = require 'lodash'
mongoose = require 'mongoose'
require './schema-extend'


Routes = require './routes'
util = require './util'

#plugin variabless
unimplemented = (req, res) -> res.status 501

#define
class Resource

  #ENTRY
  constructor: (@name, @opts = {}, @tranq) ->

    @log "added"
    _.bindAll @

    unless _.isPlainObject opts
      @error "Options must be a plain object"

    #lazy schema on non-user objs
    if not opts.schema and opts.isUser is `undefined`
      opts.schemaOpts = {} unless opts.schemaOpts
      @log "strict mode OFF"
      opts.schemaOpts.strict = false

    #apply defaults
    @opts = util.mixin {}, @tranq.defaults.resource, opts

    #this is user resource
    if @opts.isUser
      @tranq.UserResource = @
      @opts.mixins.push 'user'

    @routeName = @name.toLowerCase()
    @children = {}

  initialize: ->
    @applyMixins()
    @linkSchema()
    @defineSchema()
    @defineDatabaseMiddleware()
    @defineRoute()
    @log "initialized"
    
  #CONFIG
  applyMixins: ->
    for name in @opts.mixins
      @log "mixin:", name
      mixin = @tranq.getMixin name
      mixin @

  #SCHEMA
  linkSchema: ->

    #extract children
    for key, type of @opts.schema

      parent = @opts.schema
      #nested in 'type' check
      if _.isPlainObject(type) and type.type
        type = type.type
        parent = parent[key]

      #array check
      isArray = _.isArray(type) and type.length is 1
      type = type[0] if isArray

      #link resource
      if typeof type is 'string'
        other = @tranq.resources[type]

        #listed schema must exist
        unless other
          @error "could NOT find: #{type}"

        #convert string to objectid and store ref.
        if isArray
          parent[key] = [mongoose.Schema.ObjectId]
          @children[key] = other
        else
          parent[key] = mongoose.Schema.ObjectId

      #map across validator functions
      if _.isPlainObject(parent) and _.isArray(parent.validate)
        parent.validate = _.map parent.validate, (str) =>
          return str if typeof str isnt 'string'
          validator = @tranq.validators[str]
          @error "Missing validator: #{str}" unless validator
          return validator

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

  defineDatabaseMiddleware: ->
    set = (time, type, fn) =>
      if _.isFunction fn
        @Schema[time](type, fn)
        @log "db middleware: #{time} #{type}"
      else
        @log fn
        @error "Invalid middleware #{time} #{type}"
    
    middleware = @opts.databaseMiddleware

    for time, types of middleware
      for type, fns of types
        if _.isArray fns
          for fn in fns
            set time, type, fn
        else
          set time, type, fns
    null

  getAccess: (verb) ->

    char = verb.charAt 0

    if _.isPlainObject @opts.access
      for key, value of @opts.access
        if char is key.charAt(0)
          return value
      #not defined
      return false

    t = typeof @opts.access
    if t isnt 'string' and t isnt 'boolean'
      @error "Invalid access type: #{t}"

    @opts.access

  #ROUTES
  defineRoute: (parent) ->

    #define this resource's routes
    routes = new Routes @, parent    
    #define child routes ontop
    for n, child of @children
      child.defineRoute routes

  #helpers
  log: ->
    a = Array.prototype.slice.call arguments
    a.unshift @.toString()
    console.log.apply console, a

  error: (s) ->
    throw new Error @.toString() + " " + s

  toString: ->
    "Resource: #{@name}:"

module.exports = Resource

