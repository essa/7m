
class App.Players.MediaManager
  constructor: (@playing, @player)->
    @playing.on 'playTrack', @onPlayTrack, @
    @playing.on 'notifyStarted', @onNotifyStarted, @

  onEnded: ()->
    @playing.trigger 'notifyEnd'
    
  onNotifyStarted: ->
    return unless @track? and @list?
    nextId = @track.get('next_id') 
    nextTrack = @list.tracks.get(nextId)
    if nextTrack?
      console.log 'next', nextId, nextTrack
      @playing.set 'next_track_name', nextTrack.get('name')
      setTimeout =>
        if @playing.get('status') != App.Status.INIT
          option = @mediaOption(nextTrack)
          console.log 'prepareMedia', option
          nextTrack.prepareMedia(option)
      , 10 * 1000

class App.Players.ClientManagedMM extends App.Players.MediaManager
  onPlayTrack: (list, track, bps)->
    @list = list
    @track = track
    opt = @mediaOption()
    opt.bps = bps
    console.log 'MM#play', opt, track.mediaUrl(opt), track.get('bookmark')
    @player.play track.mediaUrl(opt), track.get('bookmark')

  onTimeUpdate: (pos)->
    @playing.trigger 'timeupdate', pos

  mediaOption: ->
    bps = App?.config?.bps()
    { bps: bps, prepareNext: 'no' }

class App.Players.ServerManagedMM extends App.Players.MediaManager
  onPlayTrack: (list, track, bps)->
    @list = list
    @track = track
    @start = parseInt(track.get('bookmark'))
    @pause = track.get('pause_at')
    @track = track
    console.log 'MM#playTrack', bps, @start, @pause
    @player.play track.mediaUrl(bps: bps, start: @start, pause: @pause), 0 

  onTimeUpdate: (pos)->
    unless @pause? and @start + pos >= @pause - 1
      @playing.trigger 'timeupdate', @start + pos

  onEnded: ()->
    if @pause?
      @playing.trigger 'skipRequest'
    else
      @playing.trigger 'notifyEnd'

  mediaOption: (track)->
    start = parseInt(track.get('bookmark'))
    pause = track.get('pause_at')
    bps = App.config.bps()
    { bps: bps, start: start, pause: pause }

class App.Players.ListMM extends App.Players.MediaManager
  onPlayTrack: (list, track, bps)->
    @posInList = parseInt(track.get('posInList'))
    @player.play list.mediaUrl(bps: bps), @posInList

    @trackEndPos = @posInList + parseInt(track.get('trimedDuration'))
    @lastPos = @posInList

  onTimeUpdate: (pos)->
    return if pos == @lastPos
    @playing.trigger 'timeupdate', pos - @posInList 
    if pos >= @trackEndPos and @lastPos < @trackEndPos
      @playing.trigger 'notifyEnd'
    @lastPos = pos
