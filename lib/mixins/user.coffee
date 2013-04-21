util = require "../util"
passport = require("passport")
mongoose = require("mongoose")
LocalStrategy = require("passport-local").Strategy
passwordHash = require('password-hash')

mixedWith = null

#public interface
module.exports = (resource) ->
  if mixedWith
    resource.error "already mixed with: #{mixedWith.name}"

  mixedWith = resource

  #configure passport
  #user -> cookie
  passport.serializeUser (user, done) ->
    console.log "serializeUser"
    done null, user.id
  #cookie -> user
  passport.deserializeUser (id, done) ->
    console.log "deserializeUser"
    resource.Model.findById id, (err, e) ->
      return done err if err
      done null, e

  #auth connector
  verify = (username, passwordAttempt, done) ->
    console.log "Login attempt: #{username}/#{passwordAttempt}"
    resource.Model.findOne { username }, (err, user) ->
      if err or not user
        return done err or null
      result = passwordHash.verify(passwordAttempt, user.password)
      done(err, if result then user else null)

  passport.use new LocalStrategy verify


  #add auth routes
  tranq = resource.tranq
  app = tranq.app

  url = tranq.opts.baseUrl + '/auth'

  app.post "#{url}/login", passport.authenticate('local'), (req, res) ->
    res.json {result: 'success', user: req.user}

  app.get "#{url}/logout", (req, res) ->
    req.logout()
    res.send 'logout'

  app.get "#{url}/user", (req, res) ->
    res.json has_user: if req.user then req.user else null

  resource.log "Added auth routes"

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
        type: [String]
    
    databaseMiddleware:
      pre:
        #hash password on the way in
        save: [
          (next) ->
            @password = passwordHash.generate @password if @password
            next()
        ]
  
    expressMiddleware: 
      pre:
        router:
          ppInit: passport.initialize()
          ppSess: passport.session()
        
  }





