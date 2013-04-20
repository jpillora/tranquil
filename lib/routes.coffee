
_ = require 'lodash'

class Routes

  parentField: '_parentId'

  constructor: (@resource, @parent) ->

    _.bindAll @

    { @Schema, @Model, @tranq } = @resource
    { @app } = @tranq

    @idField = @resource.opts.idField
    @name = @resource.routeName
    @url = "#{if @parent then @parent.url+@parent.id else @tranq.opts.baseUrl}/#{@name}"
    @id = "/:#{@name}"

    @resource.log "route:", @url+@id

    #CREATE
    @route 'create', @url
    #READ (optional id)   
    @route 'read' ,  @url+"\/?(:#{@name})?"
    #UPDATE
    @route 'update', @url+@id
    #DELETE
    @route 'delete', @url+@id

  route: (verb, path) ->

    access = @resource.getAccess verb
    
    #access false is disabled
    return if access is false

    method = @resource.opts.crudMap[verb]
    unless method
      @resource.error "Missing verb: #{verb}"

    fn = @[verb]
    unless fn
      @resource.error "Missing verb function: #{verb}"

    middleware = []

    #access true is public 
    if access isnt true
      middleware.push @roleChecker(access)

    middleware.push fn

    @app[method.toLowerCase()].apply @app, [path].concat middleware

  roleChecker: (access) ->
    (req, res, next) =>

      @resource.log "checking roles... access:", access

      unless req.user
        res.send 401, "Unauthorized" 
        return

      @resource.log "success"
      next()

  read: (req, res) ->
    if req.params[@name]
      @resource.log "found id #{req.params[@name]}"
      @Model.findOne @addIdField(req), @json(res)
    else
      @Model.find @addParentField(req), @json(res)

  create: (req, res) ->
    props = @extractFields req
    props = @addParentField req, props

    if @tranq.UserResource and req.user
      props.createdBy = req.user

    @resource.log 'create', props

    m = new @Model props
    m.save @json(res)


  update: (req, res) ->
    query = @addIdField(req)
    @Model.findOne query, @json(res, (doc) =>
      _.extend doc, @extractFields(req)
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
  extractFields: (req) ->
    req.body

  #build a query that identifies the object
  #specified in the request
  addIdField: (req, fields = {}) ->
    fields[@idField] = req.params[@name]
    @addParentField req, fields

  #build a query that identifies the object
  #specified in the request
  addParentField: (req, fields = {}) ->
    if @parent
      name = @parent.resource.routeName
      query[@parentField] = req.params[name]
    fields

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