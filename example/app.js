var tranquil = require("../");

var server = tranquil.createServer({
  baseUrl: '/api',
  resource: {
    timestamps: true,
    mixins: ['createdBy']
  }
});

server.addValidators({
  email: {
    validator: function(input) {
      return !!input.match(/@/);
    },
    msg: "yo missin da @ !"
  }
});

server.addUserResource({
  name: 'User',
  schema: {
    a: {
      type: String,
      validate: ['email']
    },
    b: Number,
    company: 'Company'
  },
  middleware: {
    post: {
      save: function(doc) {
        console.log("created user", doc.username);
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
  },
  access: {
    create: true
  }
});

server.listen(1337);

