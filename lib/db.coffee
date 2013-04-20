
mongoose = require("mongoose")

makeDatabase = (opts, callback) ->

  # throw "process.env.NODE_ENV must be set" unless process.env.NODE_ENV

  name = opts.name

  db = mongoose.createConnection(opts.host, name)

  db.on 'error', (e) ->
    console.log "Cannot create a connection to MongoDB (#{e})"
    process.exit(1);

  db.on 'open', ->
    callback() if callback

  db

module.exports = {
  makeDatabase
}