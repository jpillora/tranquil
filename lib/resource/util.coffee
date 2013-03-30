mixinAcc = (key,src,dest) ->
  s = src[key]
  d = dest[key]
  return s unless d
  return d.concat(s) if s instanceof Array and d instanceof Array
  return s if s instanceof Array or d instanceof Array
  return mixinObj(s,d) if s instanceof Object and d instanceof Object
  return s

mixinObj = (src,dest) ->
  for s of src
    dest[s] = mixinAcc s, src, dest
  dest
  
mixin = ->
  return null if arguments.length is 0
  return arguments[0] if arguments.length is 1
  
  i = arguments.length - 1
  src = arguments[i--]
  dest = null
  while i >= 0
    dest = arguments[i--]
    src = mixinObj(src,dest)
  
  return dest

#TODO
# - single elem push onto array
# - array concat single elem

# x = { a:4, c:[8,7], e:{s:0,t:2,u:1} }
# y = { b:2, c:{a:2}, e:{s:1,t:1} }
# z = { d:3 }

# print JSON.stringify mixin x,y,z

module.exports = {
  mixin
}





