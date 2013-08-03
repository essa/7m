
# Dummy Player for integration test
class App.Players.DummyPlayer extends App.PlayerBase
  createMediaManager: (playing)->
    console.log 'DummyPlayer#createMediaManager'
    @mm = new App.Players.ServerManagedMM(playing, playing.player)
    
  startMedia: (media_url, bookmark, callback)->
    console.log 'DummyPlayer#startMedia', media_url, bookmark
    $.ajax 
      url: media_url 
      success: ->
        callback()

  seek: (pos)->
    console.log 'DummyPlayer seekTo', pos

  setVolume: (v)->
    console.log 'DummyPlayer does not support volume control'
    
  fadeInOut: (inout, callback)->
    console.log 'DummyPlayer does not support volume control'
    callback()

  stop: ->
    console.log 'DummyPlayer stop'

  pause: (callback=null)->
    console.log 'DummyPlayer pause'

  continue: ->
    console.log 'DummyPlayer continue'

  onSuccess: ->
    console.log 'Media onSuccess'

  onError: (error)->
    console.log 'Media onError', error.code, error.message


