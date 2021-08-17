# README

## Description

This is a simple Ruby on Rails API for sending and retrieving chat messages. It utilizes GraphQL.

## High-level Design

A chat message is made up of a from-user and a to-user. A user can have many chat messages.

It should be noted that since there is no authentication layer implemented here, from-user is required to meaningfully create/read chat messages; however, normally this wouldn't be necessary to pass in since a token (like JWT/Bearer via custom or OAuth middleware) would be passed in to validate if: 1, a query/mutation is allowed; 2, who the user (from-user) is.

## Getting Started Instructions

* Ruby version

```text
ruby 2.6+
```

* System dependencies

```text
rails
```

* Configuration

```bash
bundle
```

* Database (in-memory/development) creation initialization

```bash
rails db:migrate RAILS_ENV=development db:seed
```

* How to run the test suite

```bash
rspec
```

* Deployment instructions

```bash
rails server
```

## Manual testing using Graphiql UI

First (after successfully deploying the server), navigate to [http://localhost:3000/graphiql](http://localhost:3000/graphiql)

Input query:

```graphql
mutation CreateChatMessage {
  createChatMessage(input: {fromUserId: 1, toUserId: 2, message: "sent from graphiql!"}) {
    clientMutationId
  }
}

query SomeQueries {
  chats(fromUserId: 1, toUserId: 2, historySince: "2021-08-16T20:31:42Z") {
    id
    timestamp
    message
    fromId
    toId
    createdAt
    updatedAt
  }
  allChats {
    id
    timestamp
    message
    fromId
    toId
    createdAt
    updatedAt
  }
  users {
    id
    username
  }
}

```

Expected Output:

```json
{
  "data": {
    "chats": [
      {
        "id": "2",
        "timestamp": "2021-08-16T20:31:42Z",
        "message": "cooler message",
        "fromId": 1,
        "toId": 2,
        "createdAt": "2021-08-16T21:49:04Z",
        "updatedAt": "2021-08-16T21:49:04Z"
      }
    ],
    "allChats": [
      {
        "id": "1",
        "timestamp": "2021-08-16T20:30:42Z",
        "message": "cool message",
        "fromId": 1,
        "toId": 2,
        "createdAt": "2021-08-16T21:49:04Z",
        "updatedAt": "2021-08-16T21:49:04Z"
      },
      {
        "id": "2",
        "timestamp": "2021-08-16T20:31:42Z",
        "message": "cooler message",
        "fromId": 1,
        "toId": 2,
        "createdAt": "2021-08-16T21:49:04Z",
        "updatedAt": "2021-08-16T21:49:04Z"
      },
      {
        "id": "3",
        "timestamp": "2021-08-16T20:32:42Z",
        "message": "even cooler message",
        "fromId": 2,
        "toId": 1,
        "createdAt": "2021-08-16T21:49:04Z",
        "updatedAt": "2021-08-16T21:49:04Z"
      },
      {
        "id": "4",
        "timestamp": "2021-08-16T20:33:42Z",
        "message": "even cooler message!",
        "fromId": 2,
        "toId": 1,
        "createdAt": "2021-08-16T21:49:04Z",
        "updatedAt": "2021-08-16T21:49:04Z"
      },
      {
        "id": "5",
        "timestamp": null,
        "message": "sent from graphiql!",
        "fromId": 1,
        "toId": 2,
        "createdAt": "2021-08-17T06:40:42Z",
        "updatedAt": "2021-08-17T06:40:42Z"
      }
    ],
    "users": [
      {
        "id": "1",
        "username": "seedUser1"
      },
      {
        "id": "2",
        "username": "seedUser2"
      }
    ]
  }
}
```
