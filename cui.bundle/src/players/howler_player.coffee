

class App.Players.HowlerPlayer extends App.PlayerBase
  createMediaManager: (playing)->
    @mm = new App.Players.ClientManagedMM(playing, playing.player)

  play: (mediaUrl, bookmark, duration)->
    @startMedia mediaUrl, bookmark, duration, =>
      console.log 'startMedia callback', mediaUrl, bookmark
      @app.trigger 'notifyStarted'
      if bookmark > 0
        @fadeInOut "in"

  startMedia: (media_url, bookmark, duration, callback)->
    vol = if bookmark? and bookmark > 0 then 0 else 1
    bookmark -= @softPauseTime 
    if bookmark < 0
      bookmark = 0

    @bookmark = bookmark
    sprite =
      playRange: [bookmark*1000, duration*1000]
    @howl = new Howl
      urls: [media_url]
      sprite: sprite
      buffer: false
      volume: vol
      onend: => @onEnded()
      onloaderror: => @onError()
      onpause: => @onPause()

      onload: => 
        console.log "howler ready", bookmark
        callback()
        @howl.play('playRange')
        @startTimeUpdate()
      onplay: -> 
        console.log "howler play start"

  startTimeUpdate: ->
    @stopTimeUpdate()
    @timer = setInterval =>
      @onTimeUpdate()
    , 1000

  stopTimeUpdate: ->
    clearTimeout(@timer) if @timer

  onTimeUpdate: (e)=>
    @mm.onTimeUpdate @howl.pos()+@bookmark

  onEnded: (e)=>
    @stopTimeUpdate()
    @mm.onEnded()

  onError: =>
    @stopTimeUpdate()
    @mm.onError()

  setVolume: (v)=>
    @howl.volume(v)

  doPause: =>
    console.log 'pause callback'
    @howl.pause()

  stop: =>
    @doPause()

  continue: =>
    @howl.play()

  seek: (pos)=>
    @howl.seek(pos)

  startSilent: -> # do nothing

