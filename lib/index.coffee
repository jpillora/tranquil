
Resource = require "./resource"
db = require "./db"
_ = require "lodash"
express = require "express"

guid = -> (Math.random()*Math.pow(2,32)).toString(16)

class Rest

  defaults:
    url: ''
    admin:
      username: "admin"
      password: guid()+guid()
    database:
      name: "banchee-rest-1"
      host: "localhost"

  constructor: (@opts) ->
    _.bindAll @
    _.defaults @opts, @defaults
    @app = express()
    @db = db.makeDatabase @opts.database, =>
      @dbReady = true
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

    #initialize all
    _.each @resources, (resource, name) ->
      resource.initialize()

      console.log resource.name, _.keys resource.children

    #admin check
    if @UserResource
      @UserResource.Model.find {}, (err, docs) =>
        @makeAdmin() if docs.length is 0

    #finally listen
    @app.configure @configure
    @app.listen port
    console.log "Listening on: #{port}"

  #admin user must be created
  makeAdmin: ->

    props = {
      username: @opts.admin.username
      password: @opts.admin.password
    }

    user = new @UserResource.Model props
    user.save (err, doc) ->
      console.log "Admin user created: #{JSON.stringify(props)}"


exports.createServer = (opts) -> new Rest opts
