### Helpers

    env = O?.env or {}

    assign = O?.assign or ( subj, obj ) -> subj[k] = v for k,v of obj; subj

    create = Object.create or do ( constructor = -> ) -> ( prototype ) ->
      constructor:: = prototype
      new constructor

    keysOf = Object.keys or = ( collection ) -> k for own k,v of collection

    isArray = Array.isArray or do ( toString = Object::toString ) ->
      ( object ) -> object? and toString.call( object ) is '[object Array]'

    resemblesArray = ( object ) ->
      object? and typeof object is 'object' and
      typeof object.length is 'number' and
      typeof object.splice is 'function'

    bitfield = ( object = {}, names, offset = 0 ) ->
      names = names.split /\s+/ if typeof names is 'string'
      object[ key ] = 1 << index + offset for key, index in names
      object

    debug = -> console.log.apply console, arguments if env.debug



### Constants

    FUTURE_COMPOSITION_ATTRIBUTES = bitfield { NORMAL: 0 }, """
      FORCE_ASYNCHRONOUS
      HAS_OBSERVERS
    """
