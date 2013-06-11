    exports = module.exports =
      ArrayIterator      : require './array-iterator'
      FutureComposition  : require './future-composition'
      Pipeline           : require './pipeline'
      Multiplex          : require './multiplex'

    exports[k] = v for k,v of require '../../will'
    exports[k] = v for k,v of require '../../might'
