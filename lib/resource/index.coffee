# build rest actions
_ = require 'lodash'
mongoose = require 'mongoose'

#plugin variabless
unimplemented = (req, res) -> res.status 501

#define
class Resource
  
  defaults:
    idField: '_id'
  
  constructor: (@name, @config = {}, @rest) ->

    _.bindAll @

    unless _.isPlainObject @config
      throw "Configuration must be a plain object"
    _.defaults @opts, @defaults

    @routeName = @name.toLowerCase()

  defineSchema: ->

  defineRoute: ->

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


module.exports = {
  set: (application) ->
    app = application

  add: (schema, opts) ->
    throw "mongooseResource.set(app) first" unless app
    r = new MongooseResource schema, opts
    resources.push r
    r
}

