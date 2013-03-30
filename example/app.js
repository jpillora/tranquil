var bancheeRest = require("../index");

console.log(bancheeRest)

var server = bancheeRest.createServer({
  url: '/api'
});

server.addValidators({
  email: {
    validator: function() {},
    msg: "blah"
  }
});


server.addResource({
  name: 'User',
  schema: {
    foo: String,
    bar: Number
  }
});

server.addResource({
  name: 'Post',
  schema: {
    foo: String,
    bar: Number
  }
});

server.addResource({
  name: 'Forum',
  schema: {
    foo: String,
    bar: Number,
    owner: 'User',
    posts: ['Post']
  }
});