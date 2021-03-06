
class App.Players.MediaManager
  constructor: (@playing, @player)->
    @playing.on 'playTrack', @onPlayTrack, @
    @playing.on 'notifyStarted', @onNotifyStarted, @

  onEnded: ()->
    @playing.trigger 'notifyEnd'
    
  onNotifyStarted: ->
    return unless @track? and @list?
    nextTrack = @list.nextUnplayed(@track)
    if nextTrack?
      console.log 'next', nextTrack
      @playing.set 'next_track_name', nextTrack.get('name')
      setTimeout =>
        if @playing.get('status') != App.Status.INIT
          options = @mediaOption(nextTrack)
          console.log 'prepareMedia', options
          options.success = =>
            @player.onPrepareMedia(options.url)
          nextTrack.prepareMedia(options)
      , 10 * 1000

  commandCallback: (status, subType)->
    StreamAudio = plugins.StreamAudio
    console.log 'commandCallback', status, subType
    switch(status)
      when StreamAudio.MEDIA_BEGININTERACTION
        console.log 'commandCallback MEDIA_BEGININTERACTION', status, subType
        # @playing.trigger 'pauseRequest' # this will start silentAudio which stop the alarm
      when StreamAudio.MEDIA_ENDINTERACTION
        console.log 'commandCallback MEDIA_ENDINTERACTION', status, subType
        @playing.trigger 'continueRequest'
      when StreamAudio.MEDIA_INPUTCHANGED
        @playing.trigger 'pauseRequest'
      when StreamAudio.MEDIA_REMOTECONTROL
        if subType <= 103
          if @playing.get("status") == App.Status.PLAYING
            @playing.trigger 'pauseRequest'
          else
            @playing.trigger 'continueRequest'
        else
          switch(subType)
            when 104
              @playing.trigger 'skipRequest'
            else
              console.log 'unsupported remote control command', subType

class App.Players.ClientManagedMM extends App.Players.MediaManager
  onPlayTrack: (list, track, options={})->
    @list = list
    if options.full
      track.set 'bookmark', 0
      track.set 'pause_at', null

    @track = track
    opt = @mediaOption()
    opt.bps = options.bps
    duration = parseInt(track.get('duration'))
    console.log 'MM#play', opt, track.mediaUrl(opt), track.get('bookmark'), duration
    @player.play track.mediaUrl(opt), track.get('bookmark'), duration

  onTimeUpdate: (pos)->
    @playing.trigger 'timeupdate', pos

  mediaOption: ->
    bps = App?.config?.bps()
    { bps: bps, prepareNext: 'no' }

class App.Players.ServerManagedMM extends App.Players.MediaManager
  onPlayTrack: (list, track, options={})->
    @list = list
    if options.full
      track.set 'bookmark', 0
      track.set 'pause_at', null
    @track = track
    @start = parseInt(track.get('bookmark'))
    @pause = track.get('pause_at')
    @track = track
    console.log 'MM#playTrack', options.bps, @start, @pause
    @player.play track.mediaUrl(bps: options.bps, start: @start, pause: @pause), 0 

  onTimeUpdate: (pos)->
    unless @pause? and @start + pos >= @pause + 10
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
  onPlayTrack: (list, track, options={})->
    @posInList = parseInt(track.get('posInList'))
    @player.play list.mediaUrl(bps: options.bps), @posInList

    @trackEndPos = @posInList + parseInt(track.get('trimedDuration'))
    @lastPos = @posInList

  onTimeUpdate: (pos)->
    return if pos == @lastPos
    @playing.trigger 'timeupdate', pos - @posInList 
    if pos >= @trackEndPos and @lastPos < @trackEndPos
      @playing.trigger 'notifyEnd'
    @lastPos = pos
