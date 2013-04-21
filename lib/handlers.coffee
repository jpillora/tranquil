module.exports =
  doc: (req, res, next) ->
    return next() unless res.doc
    res.send 200, res.doc

  err: (err, req, res, next) ->
    return next() unless err
    res.send 400, err