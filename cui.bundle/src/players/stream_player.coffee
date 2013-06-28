
class App.Players.PhonegapStreamPlayer extends App.PlayerBase
  createMediaManager: (playing)->
    console.log 'PhonegapStreamPlayer#createMediaManager'
    @mm = new App.Players.ServerManagedMM(playing, playing.player)
    
  startMedia: (media_url, bookmark, callback)->
    console.log 'PhonegapPlayer#startMedia', media_url, bookmark
    @releaseMedia()
    # media = @media = new plugins.StreamAudio media_url, @onSuccess, @onError

    # adding status callback makes app VERY SLOW!!!
    # I can't figure out why ???
    app = @app
    me = this
    media = @media = new plugins.StreamAudio media_url, ->
      me.onSuccess()
    , ->
      me.onError()
    , (status)->
      console.log 'StreamPlayer status change', status
      switch(status)
        # when StreamAudio.MEDIA_STARTING
        when 1
          console.log 'media starting', bookmark
          if bookmark? and bookmark > 5
            media.seekTo(bookmark*1000)
            # setTimeout ->
              # media.seekTo(bookmark*1000)
            # , 100
          callback()
        when 2
          app.trigger 'notifyStarted'
        when 3
          app.trigger 'notifyPaused'

    if bookmark? and bookmark > 5
      media.seekTo(bookmark*1000)
    console.log 'PhonegapPlayer#startMedia 2', media_url, bookmark
    @startMediaTimer()
    media.play()

  startMediaTimer: ->
    console.log 'startMediaTimer'
    app = @app
    media = @media
    mm = @mm
    @mediaTimer = setInterval ->
      media.getCurrentPosition (pos)->
        # console.log 'mediaTimer', pos
        mm.onTimeUpdate pos
    , 1000

  stopMediaTimer: ->
    console.log 'stopMediaTimer'
    clearInterval @mediaTimer if @mediaTimer?

  seek: (pos)->
    console.log 'StreamPlayer seekTo', pos
    @media?.seekTo(parseInt(pos)*1000)

  setVolume: (v)->
    console.log 'PhonegapStreamPlayer does not support volume control'
    
  fadeInOut: (inout, callback)->
    console.log 'PhonegapStreamPlayer does not support volume control'
    callback()

  stop: ->
    console.log 'StreamPlayer stop'
    @stopMediaTimer()
    @media?.stop()
    @releaseMedia()

  pause: (callback=null)->
    console.log 'StreamPlayer pause'
    @stopMediaTimer()
    @media?.pause()
    callback() if callback

  continue: ->
    @startMediaTimer()
    @media?.continue()

  onSuccess: ->
    console.log 'Media onSuccess'
    console.log 'Media onSuccess',  @track
    @startSilent(@app)
    @mm.onEnded()
    @releaseMedia()

  onError: (error)->
    console.log 'Media onError', error.code, error.message
    @releaseMedia()
    @app.trigger 'error', @track

  releaseMedia: ->
    clearInterval @mediaTimer if @mediaTimer?
    @media?.release()


