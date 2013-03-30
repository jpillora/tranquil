var bancheeRest = require("../index");

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
  isUser: true,
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
    //forum has 1 user
    //users have many forums
    owner: 'User'
  },
  access: {
    c: 'admin',
    r: true,
    u: ['admin', 'moderator'],
    d: false
  }
});

server.addResource({
  name: 'Post',
  schema: {
    foo: String,
    bar: Number,
    //posts have 1 forum 
    //forum has many posts
    forum: 'Forum'
  }
});

server.listen(1337);