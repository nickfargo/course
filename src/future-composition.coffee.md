## FutureComposition

Common base for **composite future constructs** such as `Pipeline`,
`Concurrency`, and `Multiplex`, which define a future in terms of the
collective result of an iterable sequence of constituent futures or functions.

    class FutureComposition extends Future

      { FORCE_ASYNCHRONOUS, HAS_OBSERVERS } =
          assign this, FUTURE_COMPOSITION_ATTRIBUTES

      { toString } = Object::
      { slice } = Array::

      getTypeOf = ( o ) ->
        toString.call( o ).match( /^\[object (\w+)\]$/ )[1]?.toLowerCase()

      isIterable = ( o ) ->
        return false unless o?
        type = getTypeOf o
        type is 'generator' or type is 'iterator' or
          typeof o.next is 'function'


### Constructor

Takes an **iterable** `source`

      constructor: ( source, @attributes ) ->
        source = source.apply this, arguments if typeof source is 'function'
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

      emit: ( eventType, args ) ->
        return unless callbacks = @events?[ eventType ]
        fn.apply this, args for fn in callbacks
        return

      promise: -> @deferral.promise()



### States

      state @::, 'abstract',

        noSuchMethod: ( name, args ) ->
          console?.error "State violation on #{ this }:" +
            " method '#{ name }'" +
            " called from state '#{ @state().path() }'" +
            " with arguments #{ args.join ', ' }"


        inactive: state 'abstract',

          incipient: state 'initial',
            admit: false
            start: ( input, DeferralConstructor = Deferral ) ->
              @context = this
              if input?
                @args = if isArray input then input[..] else [input]
              @deferral = new DeferralConstructor
              @state '-> running', arguments
              this

          resolved: state 'abstract conclusive',
            enter: ( transition, args ) -> @args = args if args

            accepted: state 'default final',
              enter: -> do @deferral.accept

            rejected: state 'final',
              enter: -> do @deferral.reject

          canceled: state 'final',
            enter: -> do @terminate


        active: state 'default abstract',

          accept: -> @state '-> accepted', arguments; this
          reject: -> @state '-> rejected', arguments; this
          cancel: -> @state '-> canceled', arguments; this

          running: state 'default'

          error: state
