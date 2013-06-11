    { bitfield } = require './helpers'



    FUTURE_COMPOSITION_ATTRIBUTES = bitfield { NORMAL: 0 }, """
      FORCE_ASYNCHRONOUS
      HAS_OBSERVERS
    """


    module.exports = {
      FUTURE_COMPOSITION_ATTRIBUTES
    }
