    { expect } = require 'chai'
    { Future, Pipeline } = require '../'
    { nextTick } = process

    log = -> console.log.apply log, arguments



    describe "Pipeline:", ->

      it "pipes values through functions synchronously", ->

        pipe = new Pipeline [
          (x) -> x * x
          (x) -> x + x
        ]
        pipe.start 4

        expect( pipe.args ).to.be.instanceof Array
        expect( pipe.args.length ).to.equal 1
        expect( pipe.args[0] ).to.equal 32


      it "vends results as a Future/promise", ( end ) ->
        pipe = new Pipeline [
          (x) -> x * x
          (x) -> x + x
        ]
        pipe.then( (a) -> expect( a ).to.equal 32 )
            .done -> do end
        pipe.start 4


      it "pipes values through functions asynchronously", ( end ) ->
        { willBe } = Future

        pipe = new Pipeline [
          (x) -> willBe x * x
          (x) -> willBe x + x
        ]
        pipe.then( (a) -> expect( a ).to.equal 32 )
            .done -> do end
        pipe.start 4


      it "integrates synchronous and asynchronous elements", ( end ) ->
        { willBe } = Future

        pipe = new Pipeline [
          (x) -> x * x
          (x) -> x + x
          (x) -> willBe x >> 3
          (x) -> willBe x * x
          (x) -> x + x
        ]
        pipe.then( (a) -> expect( a ).to.equal 32 )
            .done -> do end
        pipe.start 4


      it "processes integrated sync elements synchronously", ( end ) ->
        { willBe } = Future

        pipe = new Pipeline [
          alice = (x) -> x * x   # 16
          bob   = (x) -> x + x   # 32
          carol = (x) -> x >> 4  # 2
          dave  = (x) -> willBe ( x << x * x ) + parseInt '1010', x
        ]
        pipe.start 4

At this point the pipeline will have iterated through synchronous elements
`alice`, `bob`, and `carol`, and will be awaiting resolution of the `Future`
yielded by `dave`, into which the pipeline has passed its current value of `2`.

        expect( pipe.args[0] ).to.equal 2

        pipe.then( (a) -> expect( a ).to.equal 42 )
            .done -> do end


      describe "Catch cascading:", ->

        it "catches downstream errors", ( end ) ->
          pipe = new Pipeline -> [
            (x) -> x * x

            (x) -> throw 'just because'

            @catch ( (reason) -> reason is 'reasonable' ), ->
              expect(0).to.equal(1); "won't happen"

            (skipMe) ->
              expect(0).to.equal(1); "won't happen"

            @catch ( (reason) -> reason is 'just because' ), (reason) ->
              return 42

            (x) -> [ 'recovered!', x ]
          ]
          pipe.start 4

          pipe.then( ( message, value ) ->
              expect([ message, value ]).to.eql [ 'recovered!', 42 ]
            ).done -> do end


        it "catches downstream rejections", ( end ) ->
          pipe = new Pipeline -> [
            (x) -> x * x

            (x) -> Future.reject 'just because'

            @catch ( (reason) -> reason is 'reasonable' ), ->
              expect(0).to.equal(1); "won't happen"

            (skipMe) ->
              expect(0).to.equal(1); "won't happen"

            @catch ( (reason) -> reason is 'just because' ), (reason) ->
              return 42

            (x) -> [ 'recovered!', x ]
          ]
          pipe.start 4

          pipe.then( ( message, value ) ->
              expect([ message, value ]).to.eql [ 'recovered!', 42 ]
            ).done -> do end


        it "failure to catch rejects the pipeline", ( end ) ->
          pipe = new Pipeline -> [
            (x) -> x * x

            (x) -> Future.reject 'just because'

            @catch ( (reason) -> reason is 'reasonable' ), ->
              expect(0).to.equal(1); "won't happen"

            (skipMe) ->
              expect(0).to.equal(1); "won't happen"

            @catch ( (reason) -> reason is 'fathomable' ), ->
              expect(0).to.equal(1); "won't happen"

            (x) ->
              expect(0).to.equal(1); "won't happen"
          ]
          pipe.start 4

          pipe.then(
              -> expect(0).to.equal(1); "won't happen"
            ,
              ( reason ) ->
                expect( reason ).to.equal 'just because'
            )
            .done -> do end
