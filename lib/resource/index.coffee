# build rest actions
require './schema-extend'
_ = require 'lodash'
mongoose = require 'mongoose'

console.log "load resource"

#plugin variabless
unimplemented = (req, res) -> res.status 501

#define
class Resource
  
  defaultConfig:
    base: null
    schemaOpts:
      strict: true
    middleware: {}

  #ENTRY
  constructor: (@name, @config = {}, @rest) ->

    _.bindAll @

    unless _.isPlainObject @config
      throw "Configuration must be a plain object"

    unless @config.schema
      throw "Resource 'schema' required"

    _.defaults @config, @defaults

    @checkSchema()
    @defineSchema()
    @defineSchemaMiddleware()
    @defineRoute()

  #SCHEMA
  defineSchema: ->

    #build mongoose schema
    if typeof @config.extend is 'string'
      Extend = @rest.resources[@config.extend]
      @Schema =  Extend.extend @config.schema, @config.schemaOpts
    else
      @Schema = new mongoose.Schema @config.schema, @config.schemaOpts
    
    #build mongoose model
    @Model = @rest.db.model @name, @Schema

    @Schema.create = (props, done) =>
      x = new @Model props
      x.save done

  defineSchemaMiddleware: ->
    set = (time, type, fn) => @Schema[time](type, fn)
    
    middleware = @config.middleware

    for time of middleware
      for type of middleware[time]
        fns = middleware[time][type]
        if typeof fns is 'array'
          for fn in fns
            setMiddleware time, type, fn
        else if typeof fns is 'function'
          setMiddleware time, type, fns

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


module.exports = Resource

