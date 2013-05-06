
Resource = require "./resource"
db = require "./db"
rateLimit = require "./extensions/ratelimit"
util = require "./util"
_ = require "lodash"
express = require "express"
methods = require "methods"
requireDir = require "require-dir"

guid = -> (Math.random()*Math.pow(2,32)).toString(16)

Type =
  ROUTER: 42

class Tranquil

  defaults:
    #base url
    baseUrl: ''
    #admin user
    admin:
      username: "admin"
      password: guid()+guid()
    #mongoose
    database:
      name: "tranquil"
      host: "localhost"
    #express options
    expressCoreMiddlware:
      logger: 'dev'
      compress: true
      bodyParser: true
      cookieParser: "s3cr3t"
      session: true
    #resource defaults
    resource:
      idField: '_id'
      access: 'admin'
      crudMap:
        'create': 'POST'
        'read'  : 'GET'
        'update': 'PUT'
        'delete': 'DELETE'
      mixins: []
      schema: {}
      schemaOpts:
        strict: true
      #add mongoose middleware to this resource's schema
      databaseMiddleware: {}
      #insert express middleware into the server middleware stack
      expressMiddleware: {}
      #insert express route into the resources CRUD endpoints
      routeMiddleware: {}
    #rate limiting
    rateLimit:
      mode: 'ip' #or 'session'
      num:  1
      per: 1000

  constructor: (opts) ->

    _.bindAll @
    @opts = util.mixin {}, @defaults, opts

    @db = db.makeDatabase @opts.database, =>
      @log "Connected to MongoDB (#{@opts.database.name})"

    @mixins = requireDir "./mixins"
    @resources = {}
    @validators = {}

    @initExpress()

  initExpress: ->
    #create app
    @app = express()

    #set initial express middlware
    preRouter = {}
    for name, arg of @opts.expressCoreMiddlware
      continue if arg is false or not express[name]
      args = []
      args.push arg if arg isnt true
      preRouter[name] = express[name].apply express, args

    postRouter = {}
    postRouter.tranqDoc = @handleDoc
    postRouter.tranqErr = @handleError

    @expressMiddleware =
      pre:  { router: preRouter  }
      post: { router: postRouter }

    #intercept all route definitions
    @expressRoutes = {}
    methods.concat('all').forEach (method) =>
      @expressRoutes[method] =
        fn: @app[method]
        calls: []
      @app[method] = =>
        @expressRoutes[method].calls.push arguments

  #API
  addUserResource: (opts) ->
    if @UserResource
      @error "only 1 user resource is allowed"
    opts.isUser = true
    @UserResource = @addResource opts

  addResource: (opts) ->
    name = opts.name
    @error "Resource 'name' required" unless name
    @error "Resource '#{name}' already exists" if @resources[name]
    @resources[name] = new Resource name, opts, @

  getResource: (name) ->
    @resources[name] or @error "Missing resource: #{name}"

  addValidators: (validators) ->
    _.extend @validators, validators

  addMixin: (name, fn) ->
    @mixins[name] = fn

  #inserts middleware into the options object
  addExpressMiddleware: (obj) ->
    util.mixin @expressMiddleware, obj

  # find all middleware defined in all resources
  # combine them into a map of arrays
  _findMiddleware: ->
    m = {}

    parseExpress = (exp) ->
      for t, tObj of exp
        #add 'pre' 'post'
        m[t] = {} unless m[t]
        for name, def of tObj
          m[t][name] = [] unless m[t][name]
          addDef m[t][name], def

    addDef = (array, def) ->
      if _.isArray def
        for fn in def
          array.push { fn }
      else if _.isPlainObject def
        for name, fn of def
          array.push { name, fn }
      else if _.isFunction def
        array.push { fn }
      else
        throw "unknown type"

    #extract from tranqil
    parseExpress @expressMiddleware
    #extract from resources
    for name, resource of @resources
      exp = resource.opts.expressMiddleware
      continue unless _.isPlainObject exp
      parseExpress exp

    return m

  #root
  listResources: ->

    list = {}
    for name, resource of @resources
      list[name] =
        url: resource.routes.url
        access: resource.opts.access
        schema: _.keys resource.Schema.paths

    @app.get @opts.baseUrl, (req, res) ->
      res.json list

  handleDoc: (req, res, next) ->
    return next() unless res.doc
    res.send 200, res.doc

  handleError: (err, req, res, next) ->
    return next() unless err

    if _.isPlainObject err
      error = err.error
      status = err.status
    else
      error = err
      status = 400

    res.send status, error

  configure: ->
    @log "Express Configure"

    listMw = []
    userMw = @_findMiddleware()

    defineT = (time, name) =>
      return unless name
      objs = userMw[time]?[name]
      return unless objs

      unless _.isPlainObject objs
        @error "Invalid middleware:", objs
      for obj in objs
        define(obj.name, obj.fn)

    define = (name, mw) =>
      defineT 'pre', name
      if _.isFunction mw
        listMw.push name
        @app.use mw
      else
        console.log name, mw
        @error "Express Middleware: '#{name}' is not a function"
      defineT 'post', name

    @log userMw

    #recurrsive define middleware
    define 'router', @app.router

    @log "use middleware: [#{listMw.join ' > '}]"

  listen: (port) ->

    #cant listen with no resources
    unless Object.keys(@resources).length
      @error "At least 1 resource is required"

    #init all resources
    for name, resource of @resources
      resource.initialize()

    @log "initialized all resources"

    #setup rate limiter
    rateLimit @

    #configure express - set middleware
    @app.configure @configure

    #show api
    @listResources()
    #apply accumulated express routes
    for name, route of @expressRoutes
      continue if route.calls.length is 0
      @log 'bind', route.calls.length, name, 'handlers'
      for args in route.calls
        route.fn.apply @app, args

    #admin check
    if @UserResource
      @UserResource.Model.find {}, (err, docs) =>
        @makeAdmin() if docs.length is 0

    #finally listen
    @app.listen port

    @log "Listening on: #{port}"

  #admin user must be created
  makeAdmin: ->

    props = {
      username: @opts.admin.username
      password: @opts.admin.password
      roles: ['admin']
    }

    @log "Creating admin user: #{JSON.stringify(props)}"

    user = new @UserResource.Model props
    user.save (err, doc) =>
      @error err if err

  #helpers
  log: ->
    a = Array.prototype.slice.call arguments
    a.unshift @.toString()
    console.log.apply console, a

  error: (s) ->
    throw new Error @.toString() + " " + s

  toString: ->
    "Tranquil:"

Tranquil.Type = Type

exports.createServer = (opts) -> new Tranquil opts
