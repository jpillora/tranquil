
Resource = require "./resource"
db = require "./db"
util = require "./util"
handlers = require "./handlers"
_ = require "lodash"
express = require "express"
methods = require "methods"
requireDir = require "require-dir"

guid = -> (Math.random()*Math.pow(2,32)).toString(16)

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
    #express middleware order
    use:
      logger: express.logger("dev")
      compress: express.compress()
      bodyParser: express.bodyParser()
      cookieParser: express.cookieParser("s3cr3t")
      session: express.session()
      router: null#auto-generated
      docHandler: handlers.doc
      errHandler: handlers.err
    #resource defaults
    resource:
      idField: '_id'
      access: 'admin'
      crudMap:
        create: 'POST'
        read: 'GET'
        update: 'PUT'
        'delete': 'DELETE'
      mixins: []
      schema: {}
      schemaOpts:
        strict: true
      databaseMiddleware: {}
      expressMiddleware: {}
      routeMiddleware: {}
    #rate limiting
    rateLimit:
      mode: 'ip' #or 'session'
      num:  1
      per: 1000

  constructor: (opts) ->

    _.bindAll @

    @opts = util.mixin {}, @defaults, opts

    # @log @opts

    @app = express()

    #intercept all route definitions
    @expressRoutes = {}
    methods.concat(['all']).forEach (n) =>
      @expressRoutes[n] =
        fn: @app[n]
        calls: []
      @app[n] = =>
        @expressRoutes[n].calls.push arguments

    @db = db.makeDatabase @opts.database, =>
      @log "Connected to MongoDB (#{@opts.database.name})"

    @mixins = requireDir "./mixins"

    @resources = {}
    @validators = {}

  #API
  addUserResource: (opts) ->
    if @UserResource
      @error "only 1 user resource is allowed"
    opts.isUser = true
    @addResource opts

  addResource: (opts) ->
    name = opts.name
    @error "Resource 'name' required" unless name
    @error "Resource '#{name}' already exists" if @resources[name]
    @resources[name] = new Resource name, opts, @

  addValidators: (validators) ->
    _.extend @validators, validators

  getResource: (name) ->
    @resources[name] or @error "Missing resource: #{name}"

  addMixin: (name, fn) ->
    @mixins[name] = fn

  getMixin: (name) ->
    @mixins[name] or @error "Missing mixin: #{name}"

  # find all middleware defined in all resources
  # combine them into a multiple arrays
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

    #run
    for name, resource of @resources
      exp = resource.opts.expressMiddleware
      continue unless _.isPlainObject exp
      parseExpress exp, m

    return m

  listen: (port) ->

    #cant listen with no resources
    unless Object.keys(@resources).length
      @error "At least 1 resource is required"

    #init all resources
    for name, resource of @resources
      resource.initialize()

    @log "initialized all resources"

    #configure express
    @app.configure =>
      @log "Express Configure"

      userMw = @_findMiddleware()

      defineT = (time, name) =>
        return unless name
        objs = userMw[time]?[name]
        return unless objs
        for obj in objs
          define(obj.name, obj.fn)

      define = (name, mw) =>
        defineT 'pre', name
        mw = @app.router if name is 'router'
        @log 'use middleware', name
        @app.use mw
        defineT 'post', name

      #recurrsive define middleware
      for name, mw of @opts.use
        define name, mw

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

exports.createServer = (opts) -> new Tranquil opts
