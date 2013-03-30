
mongoose = require("mongoose")

makeDatabase = (name) ->

  throw "process.env.NODE_ENV must be set" unless process.env.NODE_ENV

  name = "#{name}-#{process.env.NODE_ENV}"

  db = mongoose.createConnection("localhost", name)

  db.on 'error', (e) ->
    console.log "Cannot create a connection to MongoDB (#{e})"
    process.exit(1);

  db.on 'open', ->
    console.log "Successfully openned a connection to MongoDB (#{name})"
  
  db

module.exports = {
  makeDatabase
}