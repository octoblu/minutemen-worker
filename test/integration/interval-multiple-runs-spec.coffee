_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
uuid       = require 'uuid'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'Multiple Runs (Interval)', ->
  before (done) ->
    @queueName = "seconds-#{uuid.v1()}"
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      done()

  before ->
    @database = mongojs "minutemen-worker-test", ['soldiers']

  beforeEach (done) ->
    @client.flushall (error) =>
      return done error if error?
      @database.soldiers.drop (error) =>
        # return done error if error?
        done()
    return # redis fix

  beforeEach ->
    @seconds = new Seconds { @client, @queueName }
    @soldier = new Soldier { @database }
    @sut     = new PaulRevere { @database, @client, @queueName, offsetSeconds: 60 }

  describe 'when intervalTime is once a second', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        done error

    beforeEach (done) ->
      metadata = {
        intervalTime: 1000,
        processNow: true,
        processAt: _.clone(@currentTimestamp)
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create the correct seconds', (done) ->
      @seconds.hasSeconds {@currentTimestamp,@recordId,intervalTime: 1000,processNow:true}, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord({ @currentTimestamp })

    describe 'wait 1 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = _.clone(@currentTimestamp + 60)
        @sut.findAndDeploySoldier @nextTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      it 'should create a new set of correct seconds', (done) ->
        @seconds.hasSeconds {currentTimestamp:@nextTimestamp, @recordId, intervalTime: 1000}, done

      it 'should have an updated record', ->
        @soldier.checkUpdatedRecord({ currentTimestamp:@nextTimestamp })

  describe 'when intervalTime is every other second', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      metadata = {
        intervalTime: 2000,
        processNow: true,
        processAt: @currentTimestamp
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create the correct seconds', (done) ->
      @seconds.hasSeconds {@currentTimestamp,@recordId,intervalTime:2000,processNow:true}, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord({ @currentTimestamp })

    describe 'wait 1 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 60
        @sut.findAndDeploySoldier @nextTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      it 'should create the correct seconds', (done) ->
        @seconds.hasSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime: 2000 }, done

      it 'should have an updated record', ->
        @soldier.checkUpdatedRecord({ currentTimestamp:@nextTimestamp })
