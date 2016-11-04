_          = require 'lodash'
moment     = require 'moment'
debug      = require('debug')('minute-man-worker:time-generator')

class TimeRange
  constructor: ({ @timestamp }) ->
    throw new Error 'TimeGenerator: requires timestamp' unless @timestamp?
    @_offsetSeconds = 60
    debug 'currentTime', @current().unix()
    debug 'max', @max().unix()
    debug 'min', @min().unix()

  offset: =>
    return @_offsetSeconds

  current: =>
    return moment.unix(@timestamp)

  max: =>
    return @_addOffset(@current().unix())

  min: =>
    return @current()

  sampleSize: =>
    return @offset() * 2

  _addOffset: (timestamp) =>
    return moment.unix(timestamp).add(@offset(), 'seconds')

module.exports = TimeRange
