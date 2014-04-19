defer = (f) -> new Promise (done, reject) => f(done, reject)
uuid = =>
  s4 = ->
    Math.floor((1 + Math.random()) * 0x10000)
               .toString(16)
               .substring(1)
  s4() + s4() + s4() + s4()

# see http://stackoverflow.com/questions/728360/most-elegant-way-to-clone-a-javascript-object
`
function clone(obj) {
    if (null == obj || "object" != typeof obj) return obj;
    var copy = obj.constructor();
    for (var attr in obj) {
        if (obj.hasOwnProperty(attr)) copy[attr] = obj[attr];
    }
    return copy;
}
`

dequal = (left, right) ->
  isLeftPrimitive  = (typeof left) in ['string', 'number', 'boolean', 'undefined']
  isRightPrimitive = (typeof right) in ['string', 'number', 'boolean', 'undefined']
  return (left is right) if isLeftPrimitive and isRightPrimitive
  return false if isLeftPrimitive or isRightPrimitive

  results =
    if left instanceof Array
      for i in left
        dequal(left[i], right[i])
    else if left instanceof Object
      for key of left
        dequal(left[key], right[key])
  (results.filter (item) -> item).length is results.length

Momic = {}
class Momic.Collection
  @dequal = dequal
  constructor: (@key, {@schema, @hasInstance, @hasPersistence, @endpoint, @autoSave}) ->
    @autoSave ?= true
    @hasPersistence ?= true
    @hasInstance ?= true

    unless @hasInstance or @hasPersistence
      throw new Error('hasInstance or hasPersistence must be true')
    @_count = 0
    @_instance = null

  _updateCount: (@_count) =>
  count: => @_count

  load: => defer (done) =>
    localforage.getItem(@key).then (content) => done(content)

  updateInstanceIfNeeded: (instance) =>
    @_instance = instance if @hasInstance

  loadContent: => defer (done) =>
    if @hasInstance and @_instance
      done(@_instance)
    else
      @load().then (content) => done(content)

  saved: => @_saved

  save: (content) => defer (done) =>
    throw "`#{@key}` collection doesn't have storage" unless @hasPersistence
    tosave = content ? @_instance
    localforage.setItem(@key, tosave).then =>
      @updateInstanceIfNeeded(tosave)
      @_saved = true
      done()

  update: (obj) => defer (done) =>
    array = if obj.length? then obj else [obj]
    @loadContent().then (content) =>
      # TODO: fix bad performance
      for item in array
        for c, n in content
          if c.id is item.id
            for key, val of item
              content[n][key] = val
            break
      @updateInstanceIfNeeded(content)
      if @autoSave
        @save(content).then => done()
      else
        @_saved = false
        done()

  insert: (obj) => defer (done) =>
    array =
      if obj.length
        obj.map (i) ->
          ret = clone(i)
          ret.id ?= uuid()
          ret
      else
        ret = clone(obj)
        ret.id ?= uuid()
        [ret]

    @loadContent().then (content) =>
      # TODO: check shema
      (content.push i) for i in array
      @_updateCount(content.length)
      if @autoSave
        @save().then =>
          @_instance = content if @hasInstance
          done()
      else
        @_saved = false
        @_instance = content if @hasInstance
        done()

  drop: => defer (done) =>
    localforage.setItem(@key, '[]').then => done()

  findOne: (func_or_obj) => defer (done) =>
    @find(func_or_obj).then ([first]) => done(first)

  find: (func_or_obj = null) => defer (done) =>
    @loadContent().then (content) =>
      results =
        if not func_or_obj?
          content
        else if (func = func_or_obj) instanceof Function
          content.filter (item) => func(item)
        else if (queryObj = func_or_obj) instanceof Object
          content.filter (item) => dequal(queryObj, item)
      done(results)

  remove: (func_or_obj) =>
    d = defer (done) =>
      c = null
      loading = defer (done) =>
        @loadContent().then (content) => # TODO: check when rewrite to Promise
          c = content
          done(content)

      loading.then (content) =>
        @find(func_or_obj).then (toremove) =>
          remove_ids = toremove.map (i) => i.id
          content = content.filter (item) => item.id not in remove_ids
          @save(content).then => done()

  init: => defer (done) =>
    localforage.getItem @key, (content) =>
      if content?
        try
          content = JSON.parse(content)
        catch e
          throw "#{@key} is not used as momic repository"
      else
        content ?= []
      @_instance = content if @hasInstance

      if @hasPersistence
        @save(content).then => done()
      else
        @_updateCount(content.length)
        done()

class Momic.DB
  collectionKey: (collectionName) =>
    @prefix + '_' + collectionName

  constructor: (opts) ->
    @initialized = false
    @prefix = opts.name
    @storage = opts?.storage or 'localforage'
    @collections =
      for key, colOpts of opts.collections
        colOpts.storage ?= @storage
        @[key] = new Momic.Collection(@collectionKey(key), colOpts)

  init: => defer (done) =>
    inits = @collections.map (col) -> col.init()
    Promise.all(inits).then =>
      @initialized = true
      done()

if (typeof define) is 'function' and (typeof define.amd) is 'object' and define.amd
  define(Momic)
else
  window.Momic = Momic
