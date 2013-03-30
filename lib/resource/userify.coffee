util = require "./util"
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
passwordHash = require('password-hash')

module.exports = (resource) ->

  #add user into into schema
  util.mixin resource, {
    schema:
      username:
        type: String
        index: true
        required: true

      password:
        type: String
        required: true
    
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
  passport.serializeUser (user, done) ->
    done null, user.id

  passport.deserializeUser (id, done) ->
    resource.model.findById id, (err, e) ->
      return done err if err
      done null, e

  passport.use new LocalStrategy {passReqToCallback:true}, (req, username, passwordAttempt, done) ->
    User.m.findOne { company: req.body.company, username }, (err, user) ->
      return done(err or null) if err or not user
      done(err, if passwordHash.verify(passwordAttempt, user.password) then user else null)


