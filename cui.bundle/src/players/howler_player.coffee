

class App.Players.HowlerPlayer extends App.PlayerBase
  createMediaManager: (playing)->
    @mm = new App.Players.ClientManagedMM(playing, playing.player)

  startMedia: (media_url, bookmark, callback)->
    vol = if bookmark? and bookmark > 0 then 0 else 1
    @howl = new Howl
      urls: [media_url]
      volume: vol
      onend: => @onEnded()
      onloaderror: => @onError()
      # onpause: => @onPause()

      onload: => 
        console.log "howler ready", bookmark
        callback()
        @howl.play()
        @howl.pos(bookmark)
        @startTimeUpdate()
      onplay: -> 
        console.log "howler play start"

  startTimeUpdate: ->
    @stopTimeUpdate()
    @timer = setInterval =>
      @onTimeUpdate()
    , 1000

  stopTimeUpdate: ->
    cancelTimer(@timer) if @timer

  onTimeUpdate: (e)=>
    @mm.onTimeUpdate @howl.pos()

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

