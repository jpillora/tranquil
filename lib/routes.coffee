
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

    @routeMiddleware 'pre', verb, middleware

    #access true is public 
    if access isnt true
      middleware.push @roleChecker(access)

    middleware.push fn

    @routeMiddleware 'post', verb, middleware

    @app[method.toLowerCase()].apply @app, [path].concat middleware

  routeMiddleware: (time, verb, middleware) ->

    ms = @resource.opts.routeMiddleware?[time]?[verb]
    return unless ms
    for m in ms
      @resource.log "route middleware:", time, verb
      middleware.push m

  roleChecker: (access) ->
    (req, res, next) =>

      @resource.log "checking roles... access:", access

      unless req.user
        res.send 401, "Unauthorized" 
        return

      @resource.log "success"
      next()

  read: (req, res, next) ->
    if req.params[@name]
      @resource.log "found id #{req.params[@name]}"
      @Model.findOne @addIdField(req), @handle(res, next)
    else
      @Model.find @addParentField(req), @handle(res, next)

  create: (req, res, next) ->
    props = @extractFields req
    props = @addParentField req, props

    if @tranq.UserResource and req.user
      props.createdBy = req.user

    m = new @Model props
    m.save @handle(res, next)

  update: (req, res, next) ->
    query = @addIdField(req)
    @Model.findOne query, @handle(res, next,
      (doc) =>
        _.extend doc, @extractFields(req)
        doc.save @handle(res, next)
    )

  delete: (req, res, next) ->
    @Model.findOne @addIdField(req), @handle(res, next,
      (doc) =>
        doc.remove @handle(res, next)
    )
  # new: (req, res) ->
  #   @handle(res)(null, _.keys(@Schema.paths))

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
  handle: (res, next, success)->
    (err, doc) ->
      if err
        next new Error { status: 400, error: err }
      else if doc is null
        next new Error { status: 404, error: "Not Found" }
      else if typeof success is 'function'
        success doc
      else 
        res.doc = doc
        next()

module.exports = Routes