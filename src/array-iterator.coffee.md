    module.exports =



## ArrayIterator

A standard iterator over an Array or array-like `source`.

    class ArrayIterator


### Constructor

      constructor: ( source ) ->
        throw TypeError unless ( length = source?.length ) and not isNaN length
        @source = source[..]
        @index = -1
        @yielded = value: undefined, done: no, index: undefined


### Methods


#### next

Any optional `input` must match the shape of `yielded`, specifically `{index}`.

      next: ( input ) ->
        { source, source:{length}, index, yielded } = this

        if input?
          { index } = input
          throw TypeError if isNaN index
          index |= 0

        @index = index += 1

        if index < length
          yielded.value = source[ index ]
          yielded.done  = no
          yielded.index = index
        else
          yielded.value = undefined
          yielded.done  = yes
          yielded.index = length
        yielded
