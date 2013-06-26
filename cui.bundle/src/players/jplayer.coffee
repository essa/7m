

class App.Players.JPlayerPlayer extends App.PlayerBase

  createMediaManager: (playing)->
    @mm = new App.Players.ClientManagedMM(playing, playing.player)

  startMedia: (media_url, bookmark, callback)->
    vol = if bookmark? and bookmark > 0 then 0 else 1
    @initJPlayer callback, =>
      jplayer = $('#jplayer')
      console.log "setting ", media_url
      jplayer.jPlayer "setMedia",
        mp3: media_url
        volume: vol
      jplayer.jPlayer "play", bookmark
      @setVolume vol

  initJPlayer: (onPlay, onReady)->
    me = this
    jplayer = $('#jplayer')
    jplayer.jPlayer "pause"
    jplayer.jPlayer "clearMedia"
    jplayer.jPlayer "destroy"
    jplayer.html ''
    jplayer.jPlayer
      swfPath: "/js/libs",
      solution:"flash, html"
      loadstart: -> console.log "jplayer loadstart"
      progress: -> console.log "jplayer progress"
      timeupdate: @onTimeUpdate
      pause: ->
        me.onPause()
      ended: @onEnded
      error: @onError
      ready: -> 
        console.log "jplayer ready"
        onReady()
      play: -> 
        console.log "jplayer play start"
        onPlay()

  onTimeUpdate: (e)=>
    sts = e.jPlayer.status
    # console.log 'Jplayer#onTimeUpdate', sts.currentTime
    @mm.onTimeUpdate sts.currentTime

  onEnded: (e)=>
    @mm.onEnded()

  onError: =>
    @mm.onError()

  setVolume: (v)=>
    jplayer = $('#jplayer')
    jplayer.jPlayer "volume", v

  doPause: =>
    console.log 'pause callback'
    jplayer = $('#jplayer')
    jplayer.jPlayer "pause"

  stop: =>
    @doPause()

  continue: =>
    jplayer = $('#jplayer')
    jplayer.jPlayer "volume", 1.0
    jplayer.jPlayer "play"

  seek: (pos)=>
    jplayer = $('#jplayer')
    jplayer.jPlayer "play", pos

  startSilent: -> # do nothing
