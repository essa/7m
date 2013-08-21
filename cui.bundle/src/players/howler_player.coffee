

class App.Players.HowlerPlayer extends App.PlayerBase
  createMediaManager: (playing)->
    @mm = new App.Players.ServerManagedMM(playing, playing.player)

  startMedia: (media_url, bookmark, callback)->
    @releaseMedia()
    vol = if bookmark? and bookmark > 0 then 0 else 1
    @howl = new Howl
      urls: [media_url]
      autoplay: true
      buffer: false
      volume: vol
      onend: => @onEnded()
      onloaderror: => @onError()
      onpause: => @onPause()

      onload: => 
        console.log "howler onload"
      onplay: => 
        console.log "howler play start"
        callback()
        @startTimeUpdate()

    unless @howl
      console.log 'howler initialize error'
      @onError()

  startTimeUpdate: ->
    console.log "howler startTimeUpdate"
    @stopTimeUpdate()
    @timer = setInterval =>
      @onTimeUpdate()
    , 1000

  stopTimeUpdate: ->
    clearTimeout(@timer) if @timer

  onTimeUpdate: (e)=>
    @mm.onTimeUpdate @howl.pos()

  # prefetch sound to cache of howler.js
  # webaudio must decode audio before playing
  # so prefetch to pre decode while previous track is playing
  onPrepareMedia: (media_url)->
    new Howl
      urls: [media_url]
      autoplay: false
      buffer: false

  onEnded: (e)=>
    @stopTimeUpdate()
    @mm.onEnded()
    @releaseMedia()

  onError: =>
    @stopTimeUpdate()
    @mm.onError()
    @releaseMedia()

  setVolume: (v)=>
    @howl?.volume(v)

  doPause: =>
    console.log 'pause callback'
    @howl?.pause()

  stop: =>
    @stopTimeUpdate()
    @doPause()
    @releaseMedia()

  continue: =>
    @startTimeUpdate()
    @howl.play()
    pos = @howl.pos()
    pos -= @softPauseTime * 2
    pos = 0 if pos < 0
    @seek(pos)
    @fadeInOut "in"

  seek: (pos)=>
    @howl.pos(pos)
    @onTimeUpdate()

  startSilent: -> # do nothing

  releaseMedia: ->
    return unless @howl
    console.log 'howl releaseMedia'
    howl = @howl
    @howl = null
    setTimeout =>
      howl.unload()
      console.log 'howl unload end'
    , 5000


