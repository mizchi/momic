// Generated by CoffeeScript 1.7.1
(function() {
  var expect;

  console.log('test start');

  expect = function(a, b) {
    if (a === b) {
      return console.log("" + a + " and " + b + " passed");
    } else {
      throw "" + a + " expected to " + b;
    }
  };

  expect(true, Momic.Collection.dequal('foo', 'foo'));

  expect(false, Momic.Collection.dequal('foo', 'bar'));

  expect(true, Momic.Collection.dequal({
    a: 1
  }, {
    a: 1
  }));

  expect(false, Momic.Collection.dequal({
    a: 1
  }, {
    a: 2
  }));

  expect(true, Momic.Collection.dequal({
    a: 1
  }, {
    a: 1,
    b: 2
  }));

  expect(false, Momic.Collection.dequal({
    a: 1,
    b: ''
  }, {
    a: 1
  }));

  expect(true, Momic.Collection.dequal({
    a: {
      b: 1
    }
  }, {
    a: {
      b: 1
    }
  }));

  expect(false, Momic.Collection.dequal({
    a: {
      b: 1
    }
  }, 1));

  expect(false, Momic.Collection.dequal({
    a: {
      b: 1
    }
  }, {}));

  expect(true, Momic.Collection.dequal({
    a: {
      b: 1
    },
    c: 2
  }, {
    a: {
      b: 1
    },
    c: 2
  }));

  expect(false, Momic.Collection.dequal({
    a: {
      b: 1
    },
    c: 3
  }, {
    a: {
      b: 1
    },
    c: 2
  }));

  localforage.setDriver('localStorageWrapper');

  window.db = new Momic.DB({
    name: 'app',
    collections: {
      items: {
        hasInstance: true,
        hasPersistence: true,
        autoSave: true
      }
    }
  });

  localforage.clear((function(_this) {
    return function() {
      return db.init().then(function() {
        var a, b;
        a = db.items.insert({
          itemType: 'weapon',
          name: 'ひのきのぼう',
          value: 10
        });
        b = db.items.insert([
          {
            itemType: 'weapon',
            name: 'てつのつるぎ',
            value: 50
          }, {
            itemType: 'weapon',
            name: 'はがねのつるぎ',
            value: 120
          }
        ]);
        return Promise.all([a, b]).then(function() {
          console.log(db.items.count());
          db.items.find().then(function(items) {
            return console.log('expect all', items);
          });
          db.items.find({
            name: 'てつのつるぎ'
          }).then(function(_arg) {
            var item;
            item = _arg[0];
            return console.log('expect てつのつるぎ', item);
          });
          db.items.findOne({
            name: 'てつのつるぎ'
          }).then(function(item) {
            return console.log('expect てつのつるぎ', item);
          });
          db.items.find(function(item) {
            return item.value > 30;
          }).then(function(items) {
            return console.log('expect てつのつるぎ はがねのつるぎ', items);
          });
          return db.items.remove(function(item) {
            return item.value > 30;
          }).then(function() {
            console.log('removed');
            return db.items.find().then(function(removed) {
              var id;
              console.log('after removed', removed);
              expect(1, removed.length);
              id = removed[0].id;
              console.log(id);
              return db.items.update({
                id: id,
                value: 42
              }).then(function() {
                console.log('updated!');
                return db.items.findOne({
                  id: id
                }).then(function(item) {
                  console.log('expect updated');
                  return expect(42, item.value);
                });
              });
            });
          });
        });
      });
    };
  })(this));

}).call(this);
