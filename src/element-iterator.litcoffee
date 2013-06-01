
    class YeOldeIterator
      constructor: ( @collection ) ->
        @index = -1

      __iterator__: -> new @constructor this

      next: ->
        { collection, index } = this
        return StopIteration unless collection.length - index > 1
        collection[ @index += 1 ]




    class MappedIterator extends ElementIterator
      constructor: ( @collection, @block ) ->
        super keysOf collection

      next: ->
        @index += 1
        @block if @elementsRemaining()

      mapArguments: ( args ) ->
        { collection } = this
        key = @elements[ @index ]
        [ collection[ key ], key, collection ]


> Don't do this. Just use an `Iterator` class that accepts a collection.

    class Collection

      constructor: ( @source ) ->

      __iterator__: -> new @Iterator @source

      class @::Iterator
        constructor: ( @collection ) ->
          { @source } = collection
          @keys = if isArray source then null else keysOf source
          @index = -1
          @exports = done: no, value: undefined

        elementsRemaining: ->
          ( @keys or @collection ).length - @index - 1

        next: ->
          { keys, collection, index, exports } = this
          { length } = keys or collection
          if length is index or length is @index = index += 1
            throw StopIteration
          key = if keys then keys[ index ] else index
          @_setExports collection[ key ], key, collection

        _setExports: ( value, key, collection ) ->
          { exports } = this
          exports.done = no
          exports.value = value
          exports




    class ArrayIterator

      constructor: ( @source ) ->
        throw TypeError unless ( length = source?.length ) and not isNaN length
        @index = -1
        @yielded = done: no, value: undefined, index: undefined


#### next

`input` must match shape of `yielded`

      next: ( input ) ->
        { source, source:{length}, yielded, index } = this

        if yielded.done
          yielded.value = undefined
          yielded.index = undefined
          return yielded

        if input?
          throw TypeError if isNaN input.index
          { index } = input

        @index = ( index |= 0 ) += 1

        yielded.done = done = index >= length
        yielded.value = source[ index ]
        yielded.index = index
        yielded



    class ObjectBasedIterator
      constructor: ( @source ) ->
        @exports = done: no, value: undefined, key: undefined
        @keys = keysOf source
        @indices =
        @index = -1

      next: ( key ) ->



    class BlockMappedCollection extends Collection

      class @::Iterator extends @::Iterator
        constructor: ( @collection, @block ) ->
          super keysOf collection

        _setExports: ( value, key, collection ) ->
          { exports } = this
          exports.element = @block
          exports.args = [ value, key, collection ]
          exports
