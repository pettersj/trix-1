class Trix.Watchdog.Recording
  @fromJSON: ({snapshots, events, frames}) ->
    new this snapshots, events, frames

  constructor: (@snapshots = [], @events = [], @frames = []) ->

  recordSnapshot: (snapshot) ->
    snapshotJSON = JSON.stringify(snapshot)
    if snapshotJSON isnt @lastSnapshotJSON
      @snapshots.push(snapshot)
      @lastSnapshotJSON = snapshotJSON
      @recordFrame()

  getSnapshotAtIndex: (index) ->
    @snapshots[index] if index >= 0

  getSnapshotAtFrameIndex: (frameIndex) ->
    snapshotIndex = @getSnapshotIndexAtFrameIndex(frameIndex)
    @getSnapshotAtIndex(snapshotIndex)

  recordEvent: (event) ->
    @events.push(event)
    @recordFrame()

  getEventAtIndex: (index) ->
    @events[index] if index >= 0

  getEventsUpToIndex: (index, size = 0) ->
    return [] if index < 0
    @events.slice(0, index + 1).slice(-size)

  getEventsUpToFrameIndex: (frameIndex, size) ->
    eventIndex = @getEventIndexAtFrameIndex(frameIndex)
    @getEventsUpToIndex(eventIndex, size)

  recordFrame: ->
    frame = [@getTimestamp(), @snapshots.length - 1, @events.length - 1]
    @frames.push(frame)

  getTimestampAtFrameIndex: (index) ->
    @frames[index]?[0]

  getSnapshotIndexAtFrameIndex: (index) ->
    @frames[index]?[1]

  getEventIndexAtFrameIndex: (index) ->
    @frames[index]?[2]

  getFrameCount: ->
    @frames.length

  getTimestamp: ->
    new Date().getTime()

  truncateToSnapshotCount: (snapshotCount) ->
    snapshotOffset = @snapshots.length - snapshotCount
    eventOffset = null
    return if snapshotOffset < 0

    frames = @frames
    @frames = for [timestamp, snapshotIndex, eventIndex] in frames when snapshotIndex >= snapshotOffset
      if eventIndex isnt -1
        eventOffset ?= eventIndex + 1
        eventIndex -= eventOffset
      snapshotIndex -= snapshotOffset
      [timestamp, snapshotIndex, eventIndex]

    @events = @events.slice(eventOffset) if eventOffset?
    @snapshots = @snapshots.slice(snapshotOffset)

  toJSON: ->
    {@snapshots, @events, @frames}