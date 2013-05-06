

module.exports = (tranq) ->

  opts = tranq.opts.rateLimit
  mode = opts.mode
  return unless mode

  OVERLIMIT = "Server Error"
  ALLOWED_MODES = ['ip','session']

  unless mode in ALLOWED_MODES
    tranq.err "Rate Limit Mode must be one of #{ALLOWED_MODES}"

  rate = opts.per / opts.num

  ips = {}

  ipMode = (req, res, next) ->
    ip = req.connection.remoteAddress
    t = new Date().getTime()
    last = ips[ip]
    if last and last+rate < t
      return next OVERLIMIT
    next()

  sessionMode = (req, res, next) ->
    next()

  fn = ipMode if mode is 'ip'
  fn = sessionMode if mode is 'session'

  tranq.addExpressMiddleware
    pre:
      router:
        rateLimit: fn