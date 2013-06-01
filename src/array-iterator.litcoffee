## ArrayIterator

A standard iterator over an Array or array-like `source`.

    class ArrayIterator

      constructor: ( source ) ->
        throw TypeError unless ( length = source?.length ) and not isNaN length
        @source = source[..]
        @index = -1
        @yielded = done: no, value: undefined, index: undefined


#### next

Any optional `input` must match the shape of `yielded`, specifically `{index}`.

      next: ( input ) ->
        { source, source:{length}, yielded, index } = this

        if yielded.done
          yielded.value = undefined
          yielded.index = length
          return yielded

        if input?
          throw TypeError if isNaN input.index
          { index } = input

        @index = index = ( index|0 ) + 1

        yielded.done = done = index >= length - 1
        yielded.value = source[ index ]
        yielded.index = index
        yielded
