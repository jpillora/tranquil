
Resource = require "./resource"
db = require "./db"
_ = require "lodash"
express = require "express"

guid = -> (Math.random()*Math.pow(2,32)).toString(16)

class Tranquil

  defaults:
    baseUrl: ''
    admin:
      username: "admin"
      password: guid()+guid()
    database:
      name: "tranquil"
      host: "localhost"
    resource:
      idField: '_id'
      access: 'admin'
      crudMap:
        create: 'POST'
        read: 'GET'
        update: 'PUT'
        'delete': 'DELETE'
      schema: {}
      schemaOpts:
        strict: true
      middleware: {}
      express: {}

  constructor: (@opts) ->
    _.bindAll @
    _.defaults @opts, @defaults

    @app = express()
    @db = db.makeDatabase @opts.database, =>
      @dbReady = true

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
    @resources[name]

  listen: (port) ->

    #cant listen with no resources
    unless Object.keys(@resources).length
      @error "At least 1 resource is required"

    #check all resources
    for name, resource of @resources
      resource.check()

    #configure express
    @app.configure =>
      @log "Express Configure"
      @app.use express.logger("dev")
      @app.use express.compress()
      @app.use express.bodyParser()
      @app.use express.methodOverride()
      @app.use express.cookieParser "s3cret"
      @app.use express.session()

      # passport = require('passport')

      # @app.use passport.initialize()
      # @app.use passport.session()

      #express options
      for name, resource of @resources
        express = resource.opts.express
        if express and _.isArray express.use
          resource.log "bind express plugins (#{express.use.length})"
          for plugin in express.use
            @app.use plugin

      @app.use @app.router

    #bind all resources
    for name, resource of @resources
      resource.bind()

    @log "initialized all resources"

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

    user = new @UserResource.Model props
    user.save (err, doc) =>
      @error err if err
      @log "Admin user created: #{JSON.stringify(props)}"
      @log doc

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
