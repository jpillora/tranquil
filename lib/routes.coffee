
_ = require 'lodash'

class Routes

  parentField: '_parentId'

  constructor: (@resource, @parent) ->

    _.bindAll @

    { @Schema, @Model, @tranq } = @resource
    { @app } = @tranq

    @idField = @resource.opts.idField
    @name = @resource.routeName
    @url = "#{@parent and @parent.url or @tranq.opts.baseUrl}/#{@name}"
    @id = "/:#{@name}"

    @resource.log "route:", @url+@id

    @routeAll()

  routeAll: ->

    @app.all "#{@url}/*", (req, res, next) =>
      @resource.log "middleware!"
      debugger
      next()

    #CREATE
    @app.post @url,    @create
    #READ (ALL)
    @app.get @url,     @index
    #READ (ONE)
    @app.get @url+@id, @show
    #UPDATE
    @app.put @url+@id, @update
    #DELETE
    @app.del @url+@id, @delete

  index: (req, res) ->
    query = {}
    @Model.find @addParentField(req), @json(res)

  create: (req, res) ->
    props = @extractFields true, req
    props = @addParentField req, query
    props.createdAt = new Date() if @tranq.opts.timestamps
    props
    m = new @Model props
    m.save @json(res)

  show: (req, res) ->
    @Model.findOne @addIdField(req), @json(res)

  update: (req, res) ->
    query = @addIdField(req)
    @Model.findOne query, @json(res, (doc) =>
      _.extend doc, @extractFields(false, req)
      doc.save @json(res)
    )

  delete: (req, res) ->
    @Model.findOne @addIdField(req), @json(res, (doc) =>
      doc.remove @json(res)
    )
  # new: (req, res) ->
  #   @json(res)(null, _.keys(@Schema.paths))

  #REQUEST HELPERS
  
  #extract schema fields from request
  extractFields: (isNew, req) ->
    fields = {}

    if @resource.opts.schemaOpts.strict
      @Schema.eachPath (p) ->
        fields[p] = req.body[p] if p of req.body
    else
      fields = req.body

    if isNew and @tranq.hasUser and req.user
      fields.createdBy = req.user

    fields

  #build a query that identifies the object
  #specified in the request
  addIdField: (req, query = {}) ->
    query[@idField] = req.params[@name]
    @addParentField req, query

  #build a query that identifies the object
  #specified in the request
  addParentField: (req, query = {}) ->
    if @parent
      name = @parent.resource.routeName
      query[@parentField] = req.params[name]
    query

  #callback function generator
  json: (res, success)->
    (err, doc) ->
      if err
        res.send 400, { error: err }
      else if doc is null
        res.send 404, "Not Found"
      else if typeof success is 'function'
        success doc
      else 
        res.json doc

module.exports = Routes