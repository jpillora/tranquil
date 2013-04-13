util = require "./util"
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
passwordHash = require('password-hash')

module.exports = (resource) ->

  console.log "userify!"

  #add user into into schema
  util.mixin resource.opts, {
    schema:
      username:
        type: String
        index: true
        required: true

      password:
        type: String
        required: true
      
      roles:
        type [String]
    
    middleware:
      pre:
        save: [
          #hash password on the way in
          (next) ->
            #console.log "check password"
            @password = passwordHash.generate @password if @password
            next()

        ]
  }

  #configure passport
  #user -> cookie
  passport.serializeUser (user, done) ->
    done null, user.id
  #cookie -> user
  passport.deserializeUser (id, done) ->
    resource.Model.findById id, (err, e) ->
      return done err if err
      done null, e

  #auth connector
  verify = (req, username, passwordAttempt, done) ->
    query = { company: req.body.company, username }
    resource.Model.findOne query, (err, user) ->
      if err or not user
        return done err or null
      result = passwordHash.verify(passwordAttempt, user.password)
      done(err, if result then user else null)

  passport.use new LocalStrategy {passReqToCallback:true}, verify

  #add routes
  {app, opts} = resource.rest

  app.get "#{opts.url}/login", passport.authenticate('local'), (req, res) ->
    res.json {result: 'success', user: req.user}

  app.get "#{opts.url}/logout", (req, res) ->
    req.logout()
    res.send 'logout'

  app.get "#{opts.url}/user", (req, res) ->
    res.json has_user: if req.user then req.user else null



