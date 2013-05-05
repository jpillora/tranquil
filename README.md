Tranquil
====

v0.0.6 Very Beta

Generate powerful RESTful JSON APIs

### Installation

`npm install tranquil`

### Usage

*Note: This API may change in the future*

Create a Tranquil server
``` javascript
var tranquil = require("tranquil");

var server = tranquil.createServer({
  baseUrl: '/api'
});
```
*Note: See all server options below*

Add some database validators
``` javascript

server.addValidators({
  email: {
    validator: function(e) {
      return !!e.match(/@/);
    },
    msg: "yo missin da @ !"
  }
});
```

Add some RESTful resources
``` javascript
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
```


Add a special user RESTful resource
``` javascript
server.addUserResource({
  name: 'User',
  schema: {
    email: {
      type: String,
      validate: ['email'] //use the email validator above
    }
  },
  databaseMiddleware: {
    post: {
      save: function(doc) {
        console.log("saved", doc);
      }
    }
  }
});
*Note: UserResources will mixin user specific fields. See below for mixins.


Finally, start the server on port `1337`
``` javascript
server.listen(1337);
```

### API

#### tranquil.`createServer`(`options`)

Creates a `server` instance which can listen on a port.

#### `server`.`addResource`(`options`)

Adds a RESTful resource to the server instance

##### `options`

**schema**: A Mongoose Schema object.

*Note: String validators and property types get replaced with tranquil validators and resources respectively*

**access**: An object which defining the access control list.

**databaseMiddleware**: Mongoose middleware definitions.

**expressMiddleware**: Express middleware definitions.

##### `server`.`addUserResource`(`options`)

...




