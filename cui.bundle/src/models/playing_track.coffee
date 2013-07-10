
class App.Models.PlayingTrack extends Backbone.Model
  defaults:
    status: App.Status.INIT
    artist: ''
    name: ''
    album: ''
    duraion: 0

  initialize: (attrs, options)->
    super(attrs, options)
    @app = options.app
    @on 'playRequest', @onPlayRequest, @
    @on 'notifyStarted', @onNotifyStarted, @
    @on 'pauseRequest', @onPauseRequest, @
    @on 'continueRequest', @onContinueRequest, @
    @on 'skipRequest', @onSkipRequest, @
    @on 'seekRequest', @onSeekRequest, @
    @on 'notifyPaused', @onPause, @
    @on 'notifyEnd', @onNotifyEnd, @
    @on 'playNextOf', @playNextOf, @
    @on 'timeupdate', @onTimeUpdate, @
    @on 'stallDetected', @onStallDetected, @
    @on 'stopRequest', @stop, @
    @on 'error', @onError, @
    @pauseAtProcessed = false
    @stallDetector = new App.Models.PlayingTrack.StallDetector(this) if @app.isPhonegap

  onPlayRequest: (playlist, track, options={})->
    console.log 'onPlayRequest', @player
    if @track and @get('status') == App.Status.PLAYING
      @player.stop() 
      @track.recordPaused(@pos)
    @list = playlist

    unless track
      @list.refresh
        async: false
        success: =>
          track = playlist.tracks.at(0) 
          @trigger 'playRequest', @list, track, options
      return 
        
    console.log 'PlayingTrack setTrack', track
    @setTrack track
    @set 'status', App.Status.SELECTED
    @playFull = options.full
    @track.fetch
      success: =>
        console.log 'pause_at', track.get('pause_at')
        @pos = track.bookmark
        @set 'status', App.Status.LOADING
        options.bps = @app.config.bps()
        @trigger 'playTrack', playlist, track, options
      error: =>
        @trigger 'error'
    @player.startSilent() if @app.isPhonegap

  onNotifyStarted: ->
    @set 'status', App.Status.PLAYING
    @pauseAtProcessed = false
    @stallDetector?.startTimer()
    # nextId = @get('next_id') 
    # nextTrack = @list.tracks.get(nextId)
    # if nextTrack?
      # console.log 'next', nextId, nextTrack
      # @set 'next_track_name', nextTrack.get('name')
      # setTimeout =>
        # if @get('status') != App.Status.INIT
          # nextTrack.prepareMedia()
      # , 30 * 1000

  onPauseRequest: ->
    console.log 'PlayingTrack onPauseRquest', @pos
    @player.pause()
    @track.recordPaused(@pos)
    @stallDetector?.stopTimer()
    @player.startSilent() if @app.isPhonegap

  onContinueRequest: ->
    console.log 'jontinueRequest'
    @player.continue()
    console.log 'continueRequest'

  onSkipRequest: ->
    return if @get('status') == App.Status.INIT
    console.log 'trigger onSkipRequest', @pos
    @track.recordPaused(@pos, completed: true)
    @player.pause =>
      @trigger 'playNextOf', @list, @track
    @stallDetector?.stopTimer()

  onSeekRequest: (pos)->
    console.log 'onSeekRequest', pos
    @player.seek(pos)

  onPause: ->
    return if @get('status') == App.Status.INIT
    @set 'status', App.Status.PAUSED
    @stallDetector?.stopTimer()

  onNotifyEnd: ->
    return if @get('status') == App.Status.INIT
    @track.recordPlayed(completed: true)
    @set 'status', App.Status.SELECTED
    @trigger 'playNextOf', @list, @track if @list
    @stallDetector?.stopTimer()

  playNextOf: (playlist, track)->
    return if @get('status') == App.Status.INIT
    unless @list
      @set 'status', App.Status.INIT
      return

    @set 'status', App.Status.SELECTED
    console.log 'playNextOf'
    status = @get('status')
    list = @list
    nextTrack = @list.getTrack(@get('next_id'))
    me = this
    setTimeout ->
      unless status == App.Status.INIT
        me.trigger 'playRequest', list, nextTrack 
    , 1000
    @player.startSilent() if @app.isPhonegap

  onTimeUpdate: (pos)->
    return if @get('status') == App.Status.INIT
    @pos = parseInt(pos)
    pause_at = @get('pause_at')
    # console.log 'onTimeUpdate', @pos, pause_at, @pauseAtProcessed
    if pause_at? and not @playFull
      # console.log 'PlayingTrack onTimeUpdate', pos, pause_at, @pauseAtProcessed
      if pos >= parseInt(pause_at) and not @pauseAtProcessed
        console.log 'trigger skipRequest'
        @trigger 'skipRequest'
        @pauseAtProcessed = true

  onStallDetected: ->
    return if @get('status') == App.Status.INIT
    console.log 'PlayingTrack onStallDetected'
    @player.pause()
    setTimeout =>
      @player.continue()
    , 500


  onError: ->
    @set 'status', App.Status.ERROR

  setTrack: (t)->
    me = this
    @track = t
    _.each ['name', 'artist', 'album', 'duration', 'bookmark', 'pause_at', 'path', 'next_id'], (prop)->
      me.set prop, t.get(prop), silent: true
    @trigger 'change'

  stop: ->
    if @track and @get('status') == App.Status.PLAYING
      @track.recordPaused(@pos)
    @set 'status', App.Status.INIT
    @stallDetector?.stopTimer()
    @player.pause()
    setInterval =>
      @player.stop()
      Env.reset()
    , 1000
    
  status: ->
    switch @get('status')
      when App.Status.INIT
        'No Track'
      when App.Status.SELECTED
        'Selected'
      when App.Status.LOADING
        'Loading...'
      when App.Status.PLAYING
        'Playing'
      when App.Status.PAUSED
        'Paused'
      else
        '???'

class App.Models.PlayingTrack.StallDetector
  constructor: (@playing)->
    @pos = 0

  startTimer: ->
    @stopTimer()
    @playing.on 'timeupdate', @onTimeUpdate, @
    @lastPos = @pos
    @timer = setInterval =>
      if @playing.get('status') == App.Status.PLAYING
        # console.log 'StallDetector check', @pos, @lastPos
        if @pos == @lastPos
          # console.log 'StallDetector fire stallDetected'
          @playing.trigger 'stallDetected'
      @lastPos = @pos
    , 5 * 1000

  onTimeUpdate: (pos)->
    # console.log 'StallDetector timeupdate', pos
    @pos = pos
    @lastUpdated = new Date()

  stopTimer: ->
    if @timer?
      clearTimeout @timer
      @timer = null
    @playing.off 'timeupdate', @onTimeUpdate






