    FutureComposition = require './future-composition'
    { state } = require '../../will'

    { isArray } = require 'util'

    { FUTURE_COMPOSITION_ATTRIBUTES } = require './constants'

    module.exports =



## Pipeline

A **pipeline** is a sequence of synchronous or asynchronous functions to be
executed in order, where each takes a set of arguments as input and returns a
value or array of values to be passed to the next as its input.

    class Pipeline extends FutureComposition

      @INSTRUCTIONS =
        SKIP: SKIP = {}
        STOP: STOP = {}
        WAIT: WAIT = {}

      { FORCE_ASYNCHRONOUS, HAS_OBSERVERS } =
          FUTURE_COMPOSITION_ATTRIBUTES

      { isFuturoid, wrap } = this
      emptySet = []


### Constructor

      constructor: ->
        super

The pipeline progresses asynchronously by passing this pair of context-bound
functions, which delegate to the pipeline’s `proceed` and `rescue` methods, to
any `Future`s or futuroids it encounters.

        @__proceed__ = => @proceed.apply this, arguments
        @__rescue__  = => @rescue.apply this, arguments



### States

      state @::,


#### active

        active: state


#### active.running

          running: state do ->
            iterate = ( @args... ) ->
              { iterator, context, invocation, attributes } = this
              { __proceed__, __rescue__ } = this

              forceAsync  = !!( attributes & FORCE_ASYNCHRONOUS )
              observed    = !!( attributes & HAS_OBSERVERS )

Internal iterators yield an additional `index` property; generators may
optionally provide an `index` by structuring their yielded `value` one level
deeper.

              try while iteration = iterator?.next iteration
                { done, value, index } = iteration
                { index, value } = value if not index? and value?.index?

Clearing `iterator` as soon as it’s `done` will end the loop after this turn.

                @iterator = iterator = null if done

Any elements that are empty or tagged `catch` can be skipped and forgotten.

                continue if not value? or value.type is 'catch'

Any function `value` is to be evaluated in the prevailing `context`, with the
prevailing `args` array as input.

                if typeof value is 'function'
                  value = value.apply context, args

When acting as an agent for an invocation, filter `value` through `invocation`.
React to an instructional signal response if one is received.

                if invocation?
                  value = invocation.evaluate value
                  continue  if value is SKIP
                  break     if value is STOP
                  return    if value is WAIT

                @emit 'willContinue', this if observed

Determine whether `value` can be treated as a future. If asynchronicity is
enforced, any non-future values must be wrapped in a `Future`.

                if value? or forceAsync
                  future = value if value instanceof Future
                  futuroid = future or isFuturoid value
                  future = value = wrap value if forceAsync and not futuroid

**Asynchronous** — defer to the `future` or `futuroid` and return immediately.

In the case of a proper `Future`, avoid the eager promise-chaining effect of
`then`, and just lazily issue continuations from inside `this` pipeline.

                  if future
                    future.once 'accepted', __proceed__
                    future.once 'rejected', __rescue__
                    return

In the case of a generic `futuroid`, fall back to calling `then`. Its returned
promise is ignored, and lazy continuation progresses inside `this` as usual.

                  else if futuroid
                    futuroid.then __proceed__, __rescue__
                    return

**Synchronous** — continue iterating over the elements until an asynchronous
continuation is encountered, or until the iterator is exhausted.

The `value` evaluated during this turn of the loop is held as the `args` array.
This is the output for this turn’s associated element of the pipeline, and will
be the input for the next element if it is a function.

A `value` of `undefined` is a signal to skip ahead synchronously and silently
pipe the received `args` to the next `element`; a `value` of `null` is a signal
to skip ahead synchronously and pipe no arguments forward.

> To pipe `null` itself, `value` must evaluate to `[null]`.

                unless value is undefined
                  @args = args = if value is null
                  then emptySet
                  else if isArray value then value else [value]

                @emit 'didContinue', this if observed

Check if we’re `pausing` on this turn and need to become `suspended`.

                return if @suspend()?

If panic strikes, hit the `error` state and bail. This will usually be caused
either by a synchronous function that threw a typical uncaught exception, or
by an asynchronous function that failed to produce its `Future` as intended.

              catch error then @rescue error; return

              @accept.apply this, @args = args
            #/function iterate

            events:
              enter: ( transition, args ) ->
                @caughtAtIndex = null
                iterate.apply this, args

            methods:
              proceed: ->
                @emit 'didContinue', this if @attributes & HAS_OBSERVERS
                ( if @iterator then iterate else @accept )
                    .apply this, arguments

              rescue: -> @state '-> error', arguments
              pause: -> @state '-> pausing'
              suspend: ->


#### active.pausing

            pausing: state
              pause: ->
              suspend: -> @state '-> suspended'
              resume: -> @state '-> running'


#### suspended

          suspended: state
            resume: -> @state '-> running'


#### error

The pipeline enters the `error` state when an element is rejected. This causes
it to pass control to the nearest downstream `catch` block that can handle the
error.

The pipeline remains in the `error` state until the `catch` is resolved. If
the `catch` is accepted, the pipeline returns to the `running` state, by
default continuing from the element after the `catch`. If the `catch` is
rejected, the pipeline is in turn rejected as well.

          error: state do ->
            iterate = ( @args... ) ->
              { iterator, context, invocation } = this
              { __proceed__, __rescue__ } = this

              try while iteration = iterator?.next iteration
                { done, value, index } = iteration
                { index, value } = value if not index? and value?.index?
                @iterator = iterator = null if done

Skip ahead to the next valid `catch` element that either lacks or satisfies an
attached `predicate` condition.

                continue unless value?.type is 'catch'
                { predicate, value } = value
                continue if typeof predicate is 'function' and
                  not predicate.apply context, args

The error is caught. Evaluate the `catch` function.

                @caughtAtIndex = index
                value = value.apply context, args

**Asynchronous catch** — If the catch value is a future, then set callbacks for
it and return immediately, remaining in the `error` state. If the catch future
is accepted, the pipeline will recover to the `running` state; if the catch
future is rejected, the pipeline will remain in the `error` state.

                if value? or forceAsync
                  future = value if value instanceof Future
                  futuroid = future or isFuturoid value
                  future = value = wrap value if forceAsync and not futuroid
                  if future
                    future.once 'accepted', __proceed__
                    future.once 'rejected', __rescue__
                    return
                  if futuroid
                    futuroid.then __proceed__, __rescue__
                    return

**Synchronous catch** — If the returned value represents a control statement,
allow an invocation to interpret and react to it; otherwise the pipeline must
automatically recover to `running`, with `value` piped to the element that
follows the `catch`.

                else
                  return if value.control? and invocation?.jump value
                  @args = args = if value is undefined
                  then emptySet
                  else if isArray value then value else [value]
                  @relay.apply this, args
                  return

An `error` thrown during iteration will supersede the previous error held in
`args`. Iteration will continue with `[error]` as the prevailing `args`.

              catch error then @rescue error; return

If no valid catch exists, or if no valid catch results in a recovery, then the
pipeline is rejected.

> If the pipeline is an agent for a containing invocation, then its rejection
> will result in the invocation entering its `error` state, thereby
> propagating the error up the invocation graph.

              @args = args
              do @reject
              this

            events:
              enter: ( transition, args ) -> iterate.apply this, args

            methods:
              proceed: ->
                @relay.apply this, arguments

              rescue: ->
                ( if @iterator then iterate else @reject )
                    .apply this, arguments

              relay: ->
                @index = @caughtAtIndex
                @state '-> running', arguments

              resume: ->
                @state '-> running', arguments

              retry: ->
                @index -= 1
                @state '-> running', arguments
