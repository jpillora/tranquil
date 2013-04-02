Tranquil
====

v0.0 (Very) Beta

Generate powerful RESTful JSON APIs

`npm install tranquil`

Beta API:

``` javascript

var tranquil = require("tranquil");

var server = tranquil.createServer({
  baseUrl: '/api'
});

server.addValidators({
  email: {
    validator: function(e) {
      return !!e.match(/@/);
    },
    msg: "yo missin da @ !"
  }
});

server.addResource({
  name: 'User',
  company: 'Company',
  isUser: true,
  schema: {
    a: {
      type: String,
      validate: ['email']
    },
    b: Number
  },
  middleware: {
    post: {
      save: function(doc) {
        console.log("saved", doc);
      }
    }
  }
});

server.addResource({
  name: 'Company',
  schema: {
    c: String,
    d: Number,
    employees: ['User'],
    owner: 'User'
  },
  //not implemented yet
  access: {
    c: 'admin',
    r: true,
    u: ['admin', 'moderator'],
    d: false
  }
});

server.addResource({
  name: 'Report',
  schema: {
    e: String,
    f: Number,
    //posts have 1 forum
    //forum has many posts
    assignedBy: 'User',
    assignedTo: 'User'
  }
});

server.listen(1337);
```