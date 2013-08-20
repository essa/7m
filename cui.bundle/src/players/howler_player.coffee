

class App.Players.HowlerPlayer extends App.PlayerBase
  createMediaManager: (playing)->
    @mm = new App.Players.ServerManagedMM(playing, playing.player)

  startMedia: (media_url, bookmark, callback)->
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

  onEnded: (e)=>
    @stopTimeUpdate()
    @mm.onEnded()
    @howl.unload()

  onError: =>
    @stopTimeUpdate()
    @mm.onError()
    @howl.unload()

  setVolume: (v)=>
    @howl.volume(v)

  doPause: =>
    console.log 'pause callback'
    @howl.pause()

  stop: =>
    @doPause()
    @howl.unload()

  continue: =>
    @fadeInOut "in"
    @howl.play()

  seek: (pos)=>
    @howl.pos(pos)

  startSilent: -> # do nothing

