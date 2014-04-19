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
