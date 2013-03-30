
mongoose = require("mongoose")

console.log "load db"

makeDatabase = (opts) ->

  # throw "process.env.NODE_ENV must be set" unless process.env.NODE_ENV

  name = opts.name

  db = mongoose.createConnection(opts.host, name)

  db.on 'error', (e) ->
    console.log "Cannot create a connection to MongoDB (#{e})"
    process.exit(1);

  db.on 'open', ->
    console.log "Successfully openned a connection to MongoDB (#{name})"
  
  db

module.exports = {
  makeDatabase
}