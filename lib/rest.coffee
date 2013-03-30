
Resource = require "./resource"
db = require "./db"
_ = require "lodash"
express = require "express"

class Rest

  defaults:
    database:
      name: "banchee-rest"
      host: "localhost"

  constructor: (@opts) ->
    _.bindAll @
    _.defaults @opts, @defaults
    @app = express()
    @db = db.makeDatabase @opts.database
    @resources = {}
    @validators = {}

  addResource: (opts) ->
    name = opts.name
    throw "Resource 'name' required" unless name
    throw "Resource '#{name}' already exists" if @resources[name] 
    @resources[name] = new Resource name, opts, @

  addValidators: (validators) ->
    _.extend @validators, validators

  configure: ->
    @app.use express.logger("dev")
    @app.use express.compress()
    @app.use express.bodyParser()
    @app.use express.methodOverride()
    @app.use express.cookieParser("r3port3r")
    @app.use express.session()

    if @hasUser
      @app.use passport.initialize()
      @app.use passport.session()
    
    @app.use @app.router

  listen: (port) ->

    # _.map @resources, (resource, name) ->
    # resource.defineSchema()
    # resource.defineSchemaMiddleware()
    # resource.defineRoute()

    #finally listen
    @app.configure @configure
    @app.listen port

exports.createServer = (opts) -> new Rest opts
