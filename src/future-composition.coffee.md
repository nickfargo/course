    { Future, Deferral, state } = require '../../will'

    { isArray } = require 'util'

    { FUTURE_COMPOSITION_ATTRIBUTES } = require './constants'

    module.exports =



## FutureComposition

Common base for **composite future constructs** such as `Pipeline`,
`Concurrency`, and `Multiplex`, which define a future in terms of the
collective result of an iterable sequence of constituent futures or functions.

    class FutureComposition extends Future
      { assign, isIterable } = require './helpers'
      ArrayIterator = require './array-iterator'

      { FORCE_ASYNCHRONOUS, HAS_OBSERVERS } =
          assign this, FUTURE_COMPOSITION_ATTRIBUTES

      @DeferralConstructor = Deferral


### Constructor

An **iterable** `source` is instated as the `iterator` of `this`. The `source`
may be provided as an array, a proper `Iterator`, or a function that returns
either, including a **generator** function.

      constructor: ( source, @attributes ) ->
        source = source.call this if typeof source is 'function'
        source = new ArrayIterator source if isArray source
        throw new TypeError unless isIterable source
        @iterator = source

        @caughtAtIndex     = undefined

        @deferral          = null
        @context           = null
        @args              = null

        @events            = null

Reference to a `FutureInvocation` being served, if applicable. This will be
set by the invocation; when not used under the auspice of an invocation (e.g. a
substituent `Pipeline` within a `Multiplex`) this value will remain `null`.

        @invocation        = null



### Methods

      on: ( eventType, callback ) ->
        unless events = @events
          @events = events = {}
          @attributes |= HAS_OBSERVERS
        ( events[ eventType ] or = [] ).push callback
        this

      once: ->
        deferral = @deferral or = new @constructor.DeferralConstructor
        deferral.once.apply deferral, arguments
        return

      emit: ( eventType, args ) ->
        return unless callbacks = @events?[ eventType ]
        fn.apply this, args for fn in callbacks
        return

      promise: -> @deferral?.promise()



### States

      state @::, 'abstract',

        noSuchMethod: ( name, args ) ->
          console?.error "State violation on #{ this }:" +
            " method '#{ name }'" +
            " called from state '#{ @state().path() }'" +
            " with arguments #{ args.join ', ' }"


#### inactive

        inactive: state 'abstract',


#### inactive.incipient

          incipient: state 'initial',
            admit: false

            start: ( input ) ->
              @context = this
              if input?
                @args = args = if isArray input then input[..] else [input]
              @deferral or = new @constructor.DeferralConstructor
              @state '-> running', args
              this

            promise: ->
              deferral = @deferral or = new @constructor.DeferralConstructor
              deferral.promise()


#### inactive.resolved

          resolved: state 'abstract conclusive',


#### inactive.resolved.completed

            completed: state 'default abstract',
              enter: ( transition, args ) -> @args = args if args

              accepted: state 'default final',
                enter: -> @deferral.accept @args...

              rejected: state 'final',
                enter: -> @deferral.reject @args...


#### inactive.resolved.canceled

            canceled: state 'final',
              enter: -> do @terminate


        active: state 'default abstract',

          accept: -> @state '-> accepted', arguments; this
          reject: -> @state '-> rejected', arguments; this
          cancel: -> @state '-> canceled', arguments; this

          running: state 'default'

          error: state
