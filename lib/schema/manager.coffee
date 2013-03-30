mongoose = require("mongoose")
require('./extend')
_ = require("lodash")

class SchemaManager

  defaults =
    schema:
      strict: true

  constructor: (@rest) ->


  create: (obj) ->

    {name, 
     base,
     schema,
     schemaOpts,
     instanceMethods,
     staticMethods,
     middleware} = obj

    #defaults
    schemaOpts ||= {}
    instanceMethods ||= {}
    staticMethods ||= {}
    middleware ||= {}

    _.defaults schemaOpts, defaults.schema

    console.log "init schema #{name}"
    throw 'Schema name required' unless name
    throw 'Schema required' unless schema

    #Schema definition
    NewSchema = (if base instanceof mongoose.Schema
      base.extend schema, schemaOpts
    else 
      new mongoose.Schema schema, schemaOpts
    )

    #Instance methods
    _.extend NewSchema.methods, instanceMethods

    #Schema ready
    model = db.model name, NewSchema

    #Class methods
    _.extend NewSchema, {
      name,
      model,
      m:model,
      create: (props, done) ->
        x = new model props
        x.save done
      find: -> 
        model.find.apply model,arguments
      findOne: -> 
        model.findOne.apply model,arguments
    }, staticMethods

    #Middleware
    setMiddleware = (time, type, fn) ->
      NewSchema[time](type, fn)
    
    for time of middleware
      for type of middleware[time]
        fns = middleware[time][type]
        if typeof fns is 'array'
          for fn in fns
            setMiddleware time, type, fn
        else if typeof fns is 'function'
          setMiddleware time, type, fns
        
    #ready
    return NewSchema

#validators
validators = {}

module.exports = {
  createSchema
  validators
}