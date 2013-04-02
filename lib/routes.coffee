

class Routes
  constructor: (@resource, baseUrl, @parent) ->

    { @Schema, @Model, @rest, @app } = @resource

    @idField = @resource.opts.idField

    @url = "#{baseUrl or @rest.opts.baseUrl}/#{@resource.routeName}"
    @id = "/:#{@resource.routeName}"

    console.log @resource.name, "route:", @url+@id

    _.bindAll @
    @routeAll()

  routeAll: ->
    #CREATE
    app.post url,   @create
    #READ (ALL)
    app.get url,    @index
    #READ (ONE)
    app.get url+id, @show
    #UPDATE
    app.put url+id, @update
    #DELETE
    app.del url+id, @delete

  index: (req, res) ->
    query = {}
    @Model.find @parentQuery(req), @json(res)

  create: (req, res) ->
    m = new @Model @extractFields(true, req)
    m.save @json(res)

  show: (req, res) ->
    @Model.findOne @idQuery(req), @json(res)

  update: (req, res) ->
    @Model.findOne @idQuery(req), @json(res), (doc) =>
      _.extend doc, @extractFields(false, req)
      doc.save @json(res)

  delete: (req, res) ->
    @Model.findOne @idQuery(req), @json(res), (doc) =>
      doc.remove @json(res)

  # new: (req, res) ->
  #   @json(res)(null, _.keys(@Schema.paths))

  #REQUEST HELPERS
  
  #extract schema fields from request
  extractFields: (isNew, req) ->
    fields = {}

    @Schema.eachPath (p) ->
      fields[p] = req.body[p] if req.body[p]

    if isNew and @rest.hasUser and req.user
      fields.createdBy = req.user

    fields

  #build a query that identifies the object
  #specified in the request
  idQuery: (req, query = {}) ->
    query[@opts.idField] = req.params[@name]
    @parentQuery req, query

  #build a query that identifies the object
  #specified in the request
  parentQuery: (req, query = {}) ->
    if @parent
      field = @parent.idField
      name = @parent.resource.routeName
      query[@idField] = req.params[name]
    query

  #callback function generator
  json: (res, success)->
    (err, doc) ->
      if err
        res.send 400, { error: err.message }
      else if doc is null
        res.send 404, "Not Found"
      else if typeof success is 'function'
        success res, doc
      else 
        res.json doc
