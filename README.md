# Momic.js

`momic.js` is mongo shell like storage API based on localforage.

This goal is providing easy and casual API for storages with structure.

## Dependencies

- es6-promises
- localforage

## API

WIP. Please see example and source, sorry.


## Example

```coffee
localforage.setDriver('localStorageWrapper')
window.db = new Momic.DB
  name: 'app'
  collections:
    items:
      # if hasInstance true, find becomes fast but has pressure to memory
      hasInstance: true # default true
      # if hasPersistence true, storage it.
      # hasInstance or hasPersistence must be true.
      hasPersistence: true # default
      autoSave: true
      # schema: # TODO: not implemented yet
      #   itemType: String
      #   name: String
      #   value: Number

localforage.clear =>
  db.init().then =>
    a = db.items.insert({itemType: 'weapon', name: 'Bat', value: 10})
    b = db.items.insert([
      { itemType: 'weapon', name: 'Iron Sword', value: 50}
      { itemType: 'weapon', name: 'Steel Sword', value: 120}
    ])

    Promise.all([a,b]).then =>
      db.items.find().then (content) =>
        console.log 'this is all content', content
        db.items.remove((item) -> item.value > 30).then =>
          db.items.find().then (afterRemoved) =>
            db.items.update(id: afterRemoved[0].id, value: 42).then =>
              db.items.findOne(id: id).then (item) =>
                expect 42, item.value

```

See `test/test.coffee` detail.

## Motivation

I have many mongodb backend applications with single page frontend. I need to perisist models and handle these like server side mongodb. But localStorage api is unlike that.

This is not for performance. Don't insert too many items. I m' not considering performance so much.

## Problems

- Now I use localforage with localStorage. Current Chrome(35) has bug about indexedDb. This is work around. See https://github.com/mozilla/localForage/issues/131

## TODO

- Add Schema feature
- Add docs
- Add more testings