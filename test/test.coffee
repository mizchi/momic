describe 'Momic.DB', ->
  beforeEach (done) ->
    localforage.setDriver('localStorageWrapper')
    localforage.clear => done()

  describe '#init', ->
    it 'should init data', (done) ->
      db = new Momic.DB
        name: 'app'
        collections:
          items: {}
      db.init().then =>
        done()

    it 'should init again after initialize', (done) ->
      db = new Momic.DB
        name: 'app'
        collections:
          items: {}
      db.init().then =>
        db.items.insert(foo: 1).then =>
          db2 = new Momic.DB
            name: 'app'
            collections:
              items: {}
          db2.init().then =>
            db2.items.findOne().then (item) =>
              expect(item.foo).eq 1
              done()

describe 'Momic.Collection', ->
  describe '.dequal', ->
    it 'should fill left statements', ->
      expect(Momic.Collection.dequal 'foo', 'foo').eq true
      expect(Momic.Collection.dequal 'foo', 'bar').eq false
      expect(Momic.Collection.dequal {a: 1}, {a: 1}).eq true
      expect(Momic.Collection.dequal {a: 1}, {a: 2}).eq false
      expect(Momic.Collection.dequal {a: 1}, {a: 1, b: 2}).eq true
      expect(Momic.Collection.dequal {a: 1, b: ''}, {a: 1}).eq false
      expect(Momic.Collection.dequal {a: {b: 1}}, {a: {b: 1}}).eq true
      expect(Momic.Collection.dequal {a: {b: 1}}, 1).eq false
      expect(Momic.Collection.dequal {a: {b: 1}}, {}).eq false
      expect(Momic.Collection.dequal {a: {b: 1}, c: 2}, {a: {b: 1}, c: 2}).eq true
      expect(Momic.Collection.dequal {a: {b: 1}, c: 3}, {a: {b: 1}, c: 2}).eq false

  describe 'Momic.DB', ->
    beforeEach (done) ->
      localforage.setDriver('localStorageWrapper')
      localforage.clear => done()

    it 'no opts', (done) ->
      db = new Momic.DB()
      expect(db.initialized).to.not.be.ok
      db.init().then =>
        expect(db).to.be.an.instanceOf Momic.DB
        expect(db.initialized).to.be.ok
        done()

    it 'use reserved word as collection name', ->
      expect( ->
        db = new Momic.DB(
          collections:
            prefix: {}
        )
      ).throw Error

    it 'initialize with collections', (done) ->
      db = new Momic.DB
        collections:
          items: {}
      db.init().then ->
        expect(db).to.have.property 'items'
        expect(db.items).to.be.an.instanceOf Momic.Collection
        done()

    it 'add collection berfore init', (done) ->
      db = new Momic.DB()
      db.addCollection('items', {})
      expect(db.items._instance).to.eql null
      db.init().then ->
        expect(db).to.property 'items'
        expect(db.items).to.be.instanceOf Momic.Collection
        expect(db.items._instance).to.eql []
        done()

    it 'add collection after init', (done) ->
      db = new Momic.DB()
      db.init().then ->
        db.addCollection("items", {}).then ->
          expect(db.items._instance).to.eql []
          done()

  context 'with localStorageWrapper', ->
    beforeEach (done) ->
      @db = null
      localforage.setDriver('localStorageWrapper')
      localforage.clear =>
        @db = new Momic.DB
          name: 'app'
          collections:
            items: {}
        @db.init().then => done()

    describe '#addPlugin', ->
      beforeEach ->
        PostSavePlugin =
          initialize: ->
          preSaveHook: ->
          postSaveHook: ->
          preInsertHook: ->
          preUpdateHook: ->

        @mock = sinon.mock(PostSavePlugin)

        @db.items.addPlugin PostSavePlugin
        @db.items.autoSave = false

      # TODO: fix
      xit 'should call postSaveHook and preSaveHook', (done) ->
        @mock.expects('initialize').once()
        @mock.expects('preSaveHook').once()
        @mock.expects('postSaveHook').once()
        @db.items.save().then =>
          @mock.verify()

      xit 'should call preInsertHook at insertion', (done) ->
        @mock.expects('preSaveHook').twice()
        @db.items.insert([{n: 1}, {n: 2}]).then ->
          @mock.verify()

      xit 'should call preUpdateHook at updating', (done) ->
        @mock.expects('postSaveHook').once()
        @db.items.insert([{id: 1}, {id: 2}]).then ->
          @db.items.insert({id: 1, foo: 'bar'}).then =>
            @mock.verify()

    describe '#insert', ->
      it 'should insert item', (done) ->
        @db.items.insert({foo: 1, bar: 2, baz: 3}).then =>
          @db.items.findOne().then (item) =>
            expect(item.foo).eq 1
            expect(item.bar).eq 2
            expect(item.baz).eq 3
            done()

      it 'should insert one item with object as argument', (done) ->
        @db.items.insert({foo: 'bar'}).then =>
          expect(@db.items.count()).eq 1
          done()

      it 'should insert one item with array as argument', (done) ->
        @db.items.insert([{foo: 'bar'}, {foo: 'baz'}]).then =>
          expect(@db.items.count()).eq 2
          done()

      it 'should create id at inserting unless id', (done) ->
        @db.items.insert({foo: 'bar'}).then =>
          @db.items.findOne().then (item) =>
            expect(item).to.have.property('id').that.is.a('string')
            done()

      it 'should not create id at inserting with id', (done) ->
        @db.items.insert({foo: 'bar', id: 'thisisid'}).then =>
          @db.items.findOne().then (item) =>
            expect(item.id).eq 'thisisid'
            done()

    describe '#saved', ->
      beforeEach ->
        @db.items.autoSave = false

      it 'should return false when items is not saved', ->
        expect(@db.items.saved()).eq true
        expect(@db.items.count()).eq 0
        @db.items.insert().then =>
          expect(@db.items.saved()).eq false
          expect(@db.items.count()).eq 1
          @db.items.save().then =>
            expect(@db.items.saved()).eq true

    describe '#find', ->
      beforeEach (done) ->
        @db.items.insert([
          {foo: 1, bar: 'a'}
          {foo: 2, bar: 'b'}
          {foo: 3, bar: 'c'}
        ]).then => done()

      it 'should fetch all with no args', (done) ->
        @db.items.find().then =>
          expect(@db.items.count()).eq 3
          done()

      it 'should fetch items by json argument', (done) ->
        @db.items.find({foo: 1}).then ([item]) =>
          expect(item.foo).eq 1
          expect(item.bar).eq 'a'
          done()

      it 'should fetch items by filter function', (done) ->
        @db.items.find((item) => item.foo > 1).then (items) =>
          expect(items.length).eq 2
          done()

    describe '#findById', ->
      beforeEach (done) ->
        @db.items.insert([
          {id: 1, content: 'a'}
          {id: 2, content: 'b'}
          {id: 3, content: 'c'}
        ]).then => done()

      it 'should one item by using index', (done) ->
        @db.items.findById(2).then (item) =>
          expect(item.content).eq 'b'
          done()
        , -> done('failed!')

    describe '#findOne', ->
      beforeEach (done) ->
        @db.items.insert([
          {foo: 1, bar: 'a'}
          {foo: 2, bar: 'b'}
          {foo: 3, bar: 'c'}
        ]).then => done()

      it 'should fetch one item of #find result', (done) ->
        @db.items.findOne((item) => item.foo > 2).then (item) =>
          expect(item.foo).eq 3
          done()

    describe '#remove', ->
      beforeEach (done) ->
        @db.items.insert([
          {foo: 1, bar: 'a'}
          {foo: 2, bar: 'b'}
          {foo: 3, bar: 'c'}
        ]).then => done()

      it 'should remove items by same argument with #find', (done) ->
        @db.items.remove((item) => item.foo > 1).then =>
          @db.items.find().then (items) =>
            expect(items.length).eq 1
            done()

    describe '#update', ->
      beforeEach (done) ->
        @db.items.insert([
          {foo: 1, bar: 'a'}
          {foo: 2, bar: 'b'}
          {foo: 3, bar: 'c'}
        ]).then => done()

      it 'should rewrite object by id', (done) ->
        @db.items.findOne(foo: 1).then (item) =>
          @db.items.update(id: item.id, foo: 42).then =>
            @db.items.findOne(bar: 'a').then (modified) =>
              expect(modified.foo).eq 42
              expect(modified.bar).eq 'a'
              done()

      it 'should rewrite object by id with array argument', (done) ->
        @db.items.find().then (items) =>
          insertions = items.map (i) => id: i.id, foo: 42
          @db.items.update(insertions).then =>
            @db.items.find().then (modifiedItems) =>
              expect(modifiedItems.map (i) -> i.foo).deep.equal [42,42,42]
              done()
