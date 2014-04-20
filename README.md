# Momic.js

![](http://www.famitsu.com/blog/otsuka/%E6%C3%97~%8E%D2-thumb.jpg)

`momic.js` is mongo shell like storage API based on mozilla's localforage. `momic` means 'mongo mimic'.

This project goal is providing useful API for storages for mongodb users.


## Dependencies

- es6-promises
- localforage

## API

All function returns promise object.


### Momic.DB

```new Momic.DB(options)```

```coffee
db = new Momic.DB
  name: 'app' # name is used for namespace prefix
  collections:
    #
    foo:
      # if hasInstance true, find becomes fast but has pressure to memory
      hasInstance: true # default true
      # if hasPersistence true, storage it.
      # hasInstance or hasPersistence must be true.
      hasPersistence: true # default
      # if autoSave is true, save automatically at `insert` and `update`
      autoSave: true # default
      # schema: # TODO: not implemented yet
      #   itemType: String
      #   name: String
      #   value: Number
    bar: {}
```

``db.init()``

You need to call `init` at first. It initializes collections and params.

```coffee
db = new Momic.DB
  name: 'app'
  collections:
    foo: {}
    bar: {}

db.init().then =>
  db.foo.find() # collections are ready.
```

### Momic.Collection

``collection#find([func_or_object])``

```coffee
col.find()               # fetch all items
col.find((i)->i.num > 5) # fetch items that num > 5 items
col.find({text: 'aaa'})  # fetch items that text is 'aaa'
col.find({text: {content: 'aaa'}})  # nested object is ok!
```

``collection#remove([func_or_object])``

```coffee
col.find()               # fetch all items
col.find((i)->i.num > 5) # fetch items that num > 5 items
col.find({text: 'aaa'})  # fetch items that text is 'aaa'
```

``collection#update([object_or_array])``

object or that array must include id.

```coffee
col.insert(id:1, text: 'a').then =>
  col.update(id:1, text: 'foo') #=> update to {id: 1, text: 'foo'}
```

``collection#save()``

```coffee
# when autoSave is true, you don't have to call it by yourself.
col.save()
```

``collection#count()``
return current colletion's count

``collection#resolved``
Boolean: current state is saved.

## Plugins

You can create your plugins with hooks

```coffee
MyPlugin = {
  initialize: (collection) -> # called with collection instance
  preInsertHook: (item) -> # called by each items to modify
  preUpdateHook: (item) -> # called by each items to modify
  preSaveHook: (items) ->  # called once before save
  postSaveHook: (items) -> # called once after save
    console.log 'collection saved!'
}

window.db = new Momic.DB
  name: 'app'
  collections:
    items:
      plugins: [MyPlugin]
```

If you want to add valide, write as your plugin.

## Example

```coffee
localforage.setDriver('localStorageWrapper')
window.db = new Momic.DB
  name: 'app'
  collections:
    items:
      hasInstance: true
      hasPersistence: true
      autoSave: true

localforage.clear =>
  db.init().then =>
    a = db.items.insert({itemType: 'weapon', name: 'Bat', value: 10})
    b = db.items.insert([
      { itemType: 'weapon', name: 'Iron Sword', value: 50}
      { itemType: 'weapon', name: 'Steel Sword', value: 120}
    ])
    Promise.all([a,b]).then =>
      db.items.find().then (content) =>
        console.log '`content` is all items', content
        db.items.remove((item) -> item.value > 30).then =>
          console.log 'Some items are removed'

```

See `test/test.coffee` detail.

## Run tests

```
bower install
npm install
npm test
```

## Motivation

I have many mongodb backend applications with single page frontend. I need to perisist models and handle these like server side mongodb. But localStorage api is unlike that.

This is not for performance. Don't insert too many items. I m' not considering performance so much.

## Problems

- Now I use localforage with localStorage. Current Chrome(35) has bug about indexedDb. This is work around. See https://github.com/mozilla/localForage/issues/131

## TODO

- Add Schema feature
- Add docs
- Drone.io (I tried but phantomjs on drone.io is old so test failed...)
