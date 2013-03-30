# build rest actions
require './schema-extend'
_ = require 'lodash'
mongoose = require 'mongoose'

LinkedResource = require './linked'
userify = require './userify'

console.log "load resource"

#plugin variabless
unimplemented = (req, res) -> res.status 501

#define
class Resource
  
  defaults:
    base: null
    schemaOpts:
      strict: true
    middleware: {}

  #ENTRY
  constructor: (@name, @opts = {}, @rest) ->

    _.bindAll @

    unless _.isPlainObject @opts
      throw "Optsuration must be a plain object"

    unless @opts.schema
      throw "Resource 'schema' required"


    console.log @name, "defaults", @defaults.middleware

    @opts = _.extend {}, @defaults, @opts

    @routeName = @name.toLowerCase()

    @checkOpts()
    @checkSchema()
    @defineSchema()
    @defineSchemaMiddleware()
    @defineRoute()
    console.log @name, "resource ready"
    
  #CONFIG
  checkOpts: ->


    console.log @name, @opts.middleware

    if @opts.isUser
      userify @
      @rest.UserResource = @

    console.log @name, @opts.middleware

  #SCHEMA
  checkSchema: ->

    #extract children
    for key, val of @opts.schema

      if _.isArray(val) and val.length is 1
        val = val[0]
        isArray = true

      if typeof val is 'string'
        other = @rest.resources[val]
        if other and other.Schema
          console.log "#{@name} found: #{other.name}"
          @opts.schema[key] = mongoose.Schema.ObjectId
        else
          throw "#{@name} could NOT find: #{val}"

  defineSchema: ->

    #build mongoose schema
    if typeof @opts.extend is 'string'
      Extend = @rest.resources[@opts.extend]
      @Schema =  Extend.extend @opts.schema, @opts.schemaOpts
    else
      @Schema = new mongoose.Schema @opts.schema, @opts.schemaOpts
    
    #build mongoose model
    @Model = @rest.db.model @name, @Schema
    #back ref
    @Schema.resource = @

  defineSchemaMiddleware: ->
    set = (time, type, fn) =>
      if typeof fn is 'function'
        @Schema[time](type, fn)
        console.log @, "set middleware: #{time} #{type}"
    
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
  defineRoute: ->
    routeName = @name.toLowerCase()


    #each resource
    #create recursing routes


  extractFields: (req) ->
    fields = {}
    @schema.eachPath (p) ->
      fields[p] = req.body[p] if p of req.body
    _.extend fields, @parentQuery(req)
    fields.createdBy = req.user if @opts.includeUser
    console.log fields
    fields

  idQuery: (req, query = {}) ->
    query[@opts.idField] = req.params[@name]
    @parentQuery req, query

  parentQuery: (req, query = {}) ->
    p = @parent
    while p
      query[p.name] = req.params[p.name]
      p = p.parent
    console.log query
    query

  json: (res, success)->
    (err, doc) ->
      if err
        res.send 400, { error: err.message }
      else if doc is null
        res.send 404, "Not Found"
      else if typeof success is 'function'
        success doc
      else 
        res.json doc

  buildActions: ->
    index: (req, res) =>
      @m.find @parentQuery(req), @json(res)
    create: (req, res) =>
      m = new @m @extractFields req
      m.save @json(res)
    show: (req, res) =>
      @m.findOne @idQuery(req), @json(res)
    update: (req, res) =>
      @m.findOne @idQuery(req), @json res, (doc) =>
        _.extend doc, @extractFields(req)
        doc.save @json(res)
    destroy: (req, res) =>
      @m.findOne @idQuery(req), @json res, (doc) =>
        doc.remove @json(res)
    edit: unimplemented
    # new: unimplemented
    new: (req, res) =>
      @json(res)(null, _.keys(@schema.paths))

  #helpers
  toString: -> @name + ": "

module.exports = Resource

