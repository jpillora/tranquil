
Resource = require "./resource"
SchemaManager = require "./resource"
db = require "./db"
_ = require "lodash"

class Rest
  constructor: (@opts) ->
    _.bindAll @
    @app = express()
    @configureApp()
    @db = db.makeDatabase "banchee-rest"
    @resources = {}
    @schemaMgr = new SchemaManager @

  add: (name, opts) ->
    throw "Resource '#{name}' already exists" if @resources[name] 
    @resources[name] = new Resource name, opts, @

  configureApp: ->
    @app.use express.logger("dev")
    @app.use express.compress()
    @app.use express.bodyParser()
    @app.use express.methodOverride()
    @app.use express.cookieParser("r3port3r")
    @app.use express.session()
    @app.use passport.initialize()
    @app.use passport.session()
    @app.use app.router

module.exports =
  createServer: (opts) -> new Rest opts
