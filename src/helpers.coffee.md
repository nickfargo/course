    { toString } = Object::

    assign = O?.assign or ( subj, obj ) -> subj[k] = v for k,v of obj; subj

    create = Object.create or do ( constructor = -> ) -> ( prototype ) ->
      constructor:: = prototype
      new constructor

    keysOf = Object.keys or = ( collection ) -> k for own k,v of collection

    resemblesArray = ( object ) ->
      object? and typeof object is 'object' and
      typeof object.length is 'number' and
      typeof object.splice is 'function'

    getTypeOf = ( o ) ->
      toString.call( o ).match( /^\[object (\w+)\]$/ )[1]?.toLowerCase()

    isIterable = ( o ) ->
      return false unless o?
      type = getTypeOf o
      type is 'generator' or type is 'iterator' or
        typeof o.next is 'function'

    bitfield = ( object = {}, names, offset = 0 ) ->
      names = names.split /\s+/ if typeof names is 'string'
      object[ key ] = 1 << index + offset for key, index in names
      object



    module.exports = {
      assign
      create
      keysOf
      resemblesArray
      isIterable
      bitfield
    }
