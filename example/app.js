var bancheeRest = require("../index");

var server = bancheeRest.createServer({
  baseUrl: '/api'
});

server.addValidators({
  email: {
    validator: function() {},
    msg: "blah"
  }
});

/*
multi-parent

file child of:
  post - has attachments (files)
  user - has dp (file)

so:

  File:
    bytes
    created
    updated

  User:
    dp - File
  Post:
    attachments - [File]


another example:

  Company:
    owner - User
    employees - [User]
    reports - [Report]

  User:
    company - Company
    reports - [Report]
  
  Report
    assignedFrom - User
    assignedTo - User
    elements - [Element]
  
  Element
    type - [ElementType]
    

*/

server.addResource({
  name: 'User',
  company: 'Company',
  isUser: true,
  schema: {
    a: String,
    b: Number
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
  }
});

server.listen(1337);

