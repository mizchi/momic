console.log 'test start'

expect = (a, b) ->
  if a is b then console.log "#{a} and #{b} passed"
  else throw "#{a} expected to #{b}"

expect true, Momic.Collection.dequal 'foo', 'foo'
expect false, Momic.Collection.dequal 'foo', 'bar'
expect true, Momic.Collection.dequal {a: 1}, {a: 1}
expect false, Momic.Collection.dequal {a: 1}, {a: 2}
expect true, Momic.Collection.dequal {a: 1}, {a: 1, b: 2}
expect false, Momic.Collection.dequal {a: 1, b: ''}, {a: 1}
expect true, Momic.Collection.dequal {a: {b: 1}}, {a: {b: 1}}
expect false, Momic.Collection.dequal {a: {b: 1}}, 1
expect false, Momic.Collection.dequal {a: {b: 1}}, {}
expect true, Momic.Collection.dequal {a: {b: 1}, c: 2}, {a: {b: 1}, c: 2}
expect false, Momic.Collection.dequal {a: {b: 1}, c: 3}, {a: {b: 1}, c: 2}

# Chrome 35's indexedDb is broken. work around
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
    a = db.items.insert({itemType: 'weapon', name: 'ひのきのぼう', value: 10})
    b = db.items.insert([
      { itemType: 'weapon', name: 'てつのつるぎ', value: 50}
      { itemType: 'weapon', name: 'はがねのつるぎ', value: 120}
    ])

    Promise.all([a,b]).then =>
      console.log db.items.count() #=> 3
      db.items.find().then (items) =>
        console.log 'expect all', items
      db.items.find({name: 'てつのつるぎ'}).then ([item]) =>
        console.log 'expect てつのつるぎ', item
      db.items.findOne({name: 'てつのつるぎ'}).then (item) =>
        console.log 'expect てつのつるぎ', item

      db.items.find((item) -> item.value > 30).done (items) =>
        console.log 'expect てつのつるぎ はがねのつるぎ', items

      removing = db.items.remove((item) -> item.value > 30)
      removing.done =>
        console.log 'removed'
        db.items.find().then (removed) =>
          console.log 'after removed', removed
          expect 1, removed.length
          id = removed[0].id
          console.log id
          db.items.update(id: id, value: 42).then =>
            console.log 'updated!'
            db.items.findOne(id: id).then (item) =>
              console.log 'expect updated'
              expect 42, item.value
