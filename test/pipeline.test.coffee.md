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
