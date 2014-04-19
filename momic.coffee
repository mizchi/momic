defer = (f) ->
  d = $?.Deferred() or Deferred?()
  f(d)
  d

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

    unless @hasPersistence or @hasPersistence
      throw new Error('hasInstance or hasPersistence must be true')
    @_count = 0
    @_instance = null

  _updateCount: (@_count) =>
  count: => @_count

  load: => defer (d) =>
    localforage.getItem(@key).then (content) => d.resolve(content)

  updateInstanceIfNeeded: (instance) =>
    @_instance = instance if @hasInstance

  loadContent: => defer (d) =>
    if @hasInstance and @_instance
      d.resolve(@_instance)
    else
      @load().then (content) => d.resolve(content)

  save: (content) => defer (d) =>
    throw "`#{@key}` collection doesn't have storage" unless @hasPersistence
    tosave = content ? @_instance
    localforage.setItem(@key, tosave).then =>
      @resolved = true
      @updateInstanceIfNeeded(tosave)
      d.resolve()

  update: (obj) => defer (d) =>
    array = if obj.length? then obj else [obj]
    @loadContent().then (content) =>
      # TODO: fix bad performance
      for item in array
        for c, n in content
          if c.id is item.id
            for key, val of item
              content[n][key] = val
            break

      @save(content).done =>
        d.resolve()

  insert: (obj) => defer (d) =>
    # array = if obj.length? then obj else [obj]
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
          d.resolve()
      else
        @resolved = false
        @_instance = content if @hasInstance
        d.resolve()

  drop: => defer (d) =>
    localforage.setItem(@key, '[]').then => d.resolve()

  findOne: (func_or_obj) => defer (d) =>
    @find(func_or_obj).then ([first]) => d.resolve(first)

  find: (func_or_obj = null) => defer (d) =>
    @loadContent().then (content) =>
      results =
        if not func_or_obj?
          content
        else if (func = func_or_obj) instanceof Function
          content.filter (item) => func(item)
        else if (queryObj = func_or_obj) instanceof Object
          content.filter (item) => dequal(queryObj, item)
      d.resolve(results)

  remove: (func_or_obj) =>
    d = defer (d) =>
      c = null
      loading = defer (d2) =>
        @loadContent().then (content) => # TODO: check when rewrite to Promise
          c = content
          d2.resolve(content)

      loading.then (content) =>
        @find(func_or_obj).then (toremove) =>
          remove_ids = toremove.map (i) => i.id
          content = content.filter (item) => item.id not in remove_ids
          @save(content).then => d.resolve()

  init: => defer (d) =>
    localforage.getItem @key, (content) =>
      if content?
        try
          cottent = JSON.parse(content)
        catch e
          throw "#{@key} is not used as momic repository"
      else
        content ?= []
      @_instance = content if @hasInstance

      if @hasPersistence
        @save(content).then => d.resolve()
      else
        @_updateCount(content.length)
        d.resolve()

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

  init: => defer (d) =>
    inits = @collections.map (col) -> col.init()
    Promise.all(inits).then =>
      @initialized = true
      d.resolve()

if (typeof define) is 'function' and (typeof define.amd) is 'object' and define.amd
  define(Momic)
else
  window.Momic = Momic
