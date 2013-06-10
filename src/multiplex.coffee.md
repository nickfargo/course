## Multiplex

A multiplex is a composite future made up of a finite number of substituent
`Pipeline`s. Elements provided to the multiplex are processed concurrently up
to the number of pipelines (`width`) at a time.

    class Multiplex extends FutureComposition


### Constructor

      constructor: ( width, source, attributes ) ->
        super source, attributes

        @width = width
        @currentWidth = 0
        @first = @last = null

        @beforeSubpipelineContinues = ( pipeline ) =>
          if @currentWidth > @width
            @currentWidth -= 1
            do pipeline.stop
          else do fill if @currentWidth < @width

        @afterSubpipelineContinues = ( pipeline ) =>
          @args = pipeline.args



### Methods


#### addPipeline

Adds a substituent pipeline acting on the same shared `@iterator` of this
multiplex.

      addPipeline: ->
        pipeline = new Pipeline @iterator
        pipeline.on 'willContinue', @beforeSubpipelineContinues
        pipeline.on 'didContinue', @afterSubpipelineContinues

        remove = => @removePipeline pipeline
        pipeline.then remove, remove

        @last = if last = @last
        then pipeline.previous = last; last.next = pipeline
        else @first = pipeline

        @currentWidth += 1
        pipeline


#### removePipeline

      removePipeline: ( pipeline ) ->
        { previous, next } = pipeline
        previous?.next = next
        next?.previous = previous
        do @accept unless previous or next
        pipeline


#### fill

      fill: ->
        do @addPipeline while @currentWidth < @width and @elementsRemaining()



### States

      state @::, do =>
        { bind, fix } = state

        inactive: state
          incipient: state
            start: fix ( autostate, protostate ) ->
              do @fill
              protostate.apply 'start', arguments

        active: state
          running: state
            addPipeline: bind ->
              pipeline = @superstate.call 'addPipeline'
              pipeline.start.apply pipeline, @owner.args
              pipeline
