
console.log "Hello SevenMinutes!"

# hook points for test
window.Env =
  reset: ->
    if window.plugins?
      vs = window.plugins.volumeSlider
      vs?.hideVolumeSlider()
    App.router.navigate('', trigger: false)
    location.reload()

originalAjax = $.ajax

ajaxNestCnt = 0
$.ajax = (options)->
  console.log 'my ajax', options.url
  ajaxNestCnt++
  $.mobile?.showPageLoadingMsg?()
  complete = options.complete
  options.timeout ||= 300 * 1000
  options.complete = (request, status)->
    console.log 'my ajax complete', options.url, status
    $.mobile?.hidePageLoadingMsg?() if --ajaxNestCnt <= 0
  originalAjax(options)

window.App = App = 
  Models: {}
  Views: {}
  Players: {}
  Status:
    INIT: 0
    SELECTED: 1
    LOADING: 2
    PLAYING: 3
    PAUSED: 4
    ERROR: 9

  initForPhonegap: ->
    console.log "initForPhonegap"
    @isPhonegap = true
    $(document).bind 'deviceready', =>
      console.log "deviceready"
      @init()
      
  initForWeb: ->
    @isPhonegap = false
    @init()
      
  init: ()->
    console.log "App.init"

    @router = new App.Router()
    @config = new App.Models.Config(this)
    @config.fetch()

    @initPlayingTrack()
    @initPlayer(@config.player())
    @initMediaManager()

    if @config.isNewConfig()
      console.log 'show config'
      location.hash = 'config'
      Backbone.history.start(pushState: false)
    else
      console.log 'show playlists'
      @initPlaylists ->
        Backbone.history.start(pushState: false)


  initPlaylists: (callback=null)->
    @programs = new App.Models.Playlists([], app: this, type: 'programs')
    @playlists = new App.Models.Playlists([], app: this, type: 'playlists')
    $.when(@programs.fetch(), @playlists.fetch()).then ->
      console.log 'then'
      callback() if callback
    , ->
      alert("can't connect to server")
      location.hash = 'config'
      callback() if callback

  initPlayer: (player)->
    return false unless player
    @player.stop() if @player?
    playerClass = App.Players[player]
    return false unless playerClass?
    @playing.player = @player = new playerClass(this) 
    return true

  initPlayingTrack: ->
    console.log 'initPlayingTrack'
    @playing = new App.Models.PlayingTrack({}, app: this)

  initMediaManager: ->
    console.log 'initMediaManager'
    if @playing.player?
      @mediaManager = @playing.player.createMediaManager(@playing)

  baseUrl: ->
    server_addr = @config.get('server_addr')
    server_port = @config.get('server_port')
    if server_addr? and server_addr != '' 
      if server_port? and server_port != ''
        "http://#{server_addr}:#{server_port}/"
      else
        "http://#{server_addr}/"
    else
      "/"

  on: (args...)->
    @playing.on.apply @playing, arguments

  off: (args...)->
    @playing.off.apply @playing, arguments

  trigger: (args...)->
    console.log 'App.trigger', args unless args[0] == 'timeupdate'
    @playing.trigger.apply @playing, arguments

  hasTrackPlaying: ->
    status = @playing.get('status')
    status != App.Status.INIT

  changeView: (newView, options={})->
    oldView = @currentView
    console.log 'changeView', oldView, newView
    options.changeHash = false

    if oldView?
      oldView.close()
      if newView.seq >= oldView.seq
        options.reverse = false
        options.transition = newView.transition
      else
        options.reverse = true
        options.transition = oldView.transition
    else
      options.reverse = false
      options.transition = null

    newView.render()
    newView.$el.trigger 'pagecreate'
    $.mobile.changePage newView.$el, options
    @currentView = newView

  Router: Backbone.Router.extend
    routes:
      "": "playlists"
      "config": "config"
      "programs/:playlist_id": "program"
      "programs/:playlist_id/tracks/:track_id": "program_track"
      "playlists/:playlist_id": "playlist"
      "playlists/:playlist_id/tracks/:track_id": "playlist_track"
      "playing(/:type/*song)": "playing"
      "playlists": "playlists" # for test only

    playlists: ->
      console.log 'Router#playlists', @currentView
      unless App.programs and App.playlists and App.programs.length > 0 and App.playlists.length > 0
        # location.reload()
        Env.reset()
        
      App.stopped = false
      viewClass = App.Views.PlaylistsView 
      viewClass = App.Views.PlaylistsViewOld if App.config.get('face') == 'mobileold' 
      view = new viewClass
        app: App
        el: $("#page")
        programs: App.programs
        playlists: App.playlists
        hasFlash: App.config.hasFlash()
      App.changeView view

    config: ->
      console.log "Router#config", App.config
      view = new App.Views.ConfigView
        app: App
        el: $("#page")
        model: App.config
      App.changeView view

    program: (id)->
      console.log 'Router#program', id, @currentView
      @showPlaylistView(App.programs, id)

    playlist: (id)->
      console.log 'Router#playlist', id, @currentView
      @showPlaylistView(App.playlists, id)

    showPlaylistView: (collection, id)-> 
      viewClass = if App.config.hasFlash() or App.isPhonegap
        App.Views.PlaylistViewForEmbendedPlayer
      else
        App.Views.PlaylistViewForExternalPlayer

      pl = collection.get(id)
      if pl?
        pl.tracks.fetch
          success: ->
            view = new viewClass
              app: App
              el: $("#page")
              model: pl
              type: collection.type
              hasFlash: App.config.hasFlash()
            App.changeView view
        App.currentPlaylist = pl 
      else
        alert("can't find playlist id#{id}")
            
    program_track: (playlist_id, track_id)->
      @track('programs', playlist_id, track_id)

    playlist_track: (playlist_id, track_id)->
      @track('playlists', playlist_id, track_id)

    track: (type, playlist_id, track_id)->
      console.log "Router#track", type, playlist_id, track_id
      col = App[type]
      pl = col.get(playlist_id)
      if pl?
        App.currentPlaylist = pl 
        pl.tracks.fetch
          success: ->
            track = pl.tracks.get(track_id)
            if track
              view_class = if App.config.hasFlash() or App.isPhonegap
                App.Views.TrackViewForEmbendedPlayer
              else
                App.Views.TrackViewForExternalPlayer

              view = new view_class
                app: App
                el: $("#page")
                model: track
                type: type
                playlist: pl
              App.changeView view
            else
              App.router.navigate('playlists', trigger: true)

    playing: (type, song)->
      if song? and song != ''
        [playlist_id, track_id] = song.split('/')
        console.log "Router#playing", type, playlist_id, track_id
        col = App[type]
        list = col.get(playlist_id)
        track = list.getTrack(track_id)
        App.trigger 'playRequest', list, track

      view = new App.Views.PlayerUIView
        el: $('#page')
        model: App.playing
      App.changeView view

class App.PlayerBase
  constructor: (@app)->
    console.log 'PlayerBase#constructor'
    @softPauseTime = 2.0

  stop: ->
    console.log 'Player stop'
    @app.off()

  play: (mediaUrl, bookmark)->
    @startMedia mediaUrl, bookmark, =>
      console.log 'startMedia callback', mediaUrl, bookmark
      @app.trigger 'notifyStarted'
      if bookmark > 0
        @fadeInOut "in"

  fadeInOut: (inout, callback)->
    console.log "fade #{inout} start"
    setVolume = @setVolume
    interval = 100
    vDelta = interval / (@softPauseTime * 1000)
    [v, vDelta, finishCond] = switch inout
      when 'in'
        [0.0, vDelta, ((v)-> v>= 1.0)]
      when 'out'
        [1.0, vDelta * -1, ((v)-> v <= 0.0)]
      else
        console.log 'cant happen'

    cnt = 0
    timer = setInterval ->
      # console.log 'fadeinout', v
      setVolume(v)
      v += vDelta
      if finishCond(v) or ++cnt > 10000 / interval
        console.log "fade #{inout} end"
        clearInterval(timer)
        callback() if callback
    , interval

  pause: (callback=null)->
    console.log 'pause'
    doPause = @doPause
    @fadeInOut 'out', ->
      doPause()
      callback() if callback

  onPause: ->
    console.log 'onPause'
    @app.trigger 'notifyPaused'

  stop: (callback=null)->
    console.log 'stop'
    doStop = @doStop
    @fadeInOut 'out', ->
      doStop()
      callback() if callback
  
  startSilent: ->
    new App.Players.SilentAudioPlayer(@app).play()

class App.Players.PhonegapMediaPlayer extends App.PlayerBase
  startMedia: (media_url, bookmark, callback)->
    console.log 'PhonegapPlayer#startMedia', media_url, bookmark
    @releaseMedia()

    me = this
    media = @media = new Media media_url, ->
      me.onSuccess()
    , -> 
      me.onError()

    media.play()
    media.seekTo(bookmark*1000) if bookmark? > 0
    app = @app
    @mediaTimer = setInterval ->
      media.getCurrentPosition (pos)->
        app.trigger 'timeupdate',  pos
    , 1000
    #@showVolumeSlider()
    callback()

  showVolumeSlider: ->
    console.log 'showVolumeSlider', window.plugins.volumeSlider
    volumeSlider = window.plugins.volumeSlider
    volumeSlider.createVolumeSlider(10,350,300,30)
    volumeSlider.showVolumeSlider()
    console.log 'showVolumeSlider end'

  seek: (pos)->
    @media?.seekTo(pos*1000)

  setVolume: (v)->
    @media?.setVolume(v)

  doPause: ->
    console.log 'pause'
    clearInterval @mediaTimer if @mediaTimer?
    @media?.pause()

  onSuccess: ->
    console.log 'Media onSuccess',  @track
    @startSilent(@app)
    setTimeout =>
      @releaseMedia()
      @app.trigger 'ended', @track
    , 1000

  onError: (error)->
    console.log 'Media onError', error.code, error.message
    @releaseMedia()
    @app.trigger 'error', @track

  releaseMedia: ->
    clearInterval @mediaTimer if @mediaTimer?
    @media?.release()
    
class App.Players.ITunesPlayer
  constructor: (@app)->
    console.log 'ITunes#constructor'
    @softPauseTime = 2.0
    @app.on
      play: @playTrack
      pause: @pause

  stop: ->
    @app.off()

  playTrack: (@track)=>
    console.log 'playTrack'
    clearTimeout(@timer) if @timer?
    $.ajax
      url: "#{@track.url()}/play"
      method: 'post'
      success: @notifyAtEnd
      data: JSON.stringify
        command: 'play'

  notifyAtEnd: =>
    time = (parseInt(@track.get('duration')) - parseInt(@track.get('bookmark'))) * 1000
    console.log 'timer start', time
    @timer = setTimeout =>
      console.log 'timer fire', 
      @app.trigger 'ended', @track
    , time 

  pause: =>
    console.log 'ITunesPlayer#pause'
    clearTimeout(@timer) if @timer?
    $.ajax
      url: "#{@track.url()}/play"
      method: 'post'
      success: @notifyEnd
      data: JSON.stringify
        command: 'pause'
    
# special player for holding audio session by playing silent mp3 file
class App.Players.SilentAudioPlayer
  constructor : (@app)->
    console.log 'SilentAudio#constructor'
    fname = 'sound/silent.mp3'
    @silentmp3 = new Media fname, @onSuccess, @onError
    # url = 'http://192.168.1.10:3000/sound/silent.mp3'
    # @silentmp3 = new plugins.StreamAudio url, @onSuccess, @onError

    console.log 'SilentAudio#constructor end'

  play: ->
    console.log 'silient play'
    @silentmp3.play
      numberOfLoops: 10
  
  pause: ->
    console.log 'silient pause'
    @silentmp3.pause()

  onSuccess: ->
    console.log 'silient success'

  onError: ->
    console.log 'silent error'



class App.Views.HeaderRenderer extends Backbone.View
  template: _.template '''
    <% if (typeof left_icon != 'undefined') { %>
      <a <%= left_id_attr %> href='#<%= left_href %>' data-role="button" data-icon="<%= left_icon %>"  data-iconpos="notext"></a>
    <% } %>
    <h1><%= title %></h1>
    <% if (typeof right_icon != 'undefined') { %>
      <a <%= right_id_attr %> href='#<%= right_href %>' data-role="button" data-icon="<%= right_icon %>"  data-iconpos="notext" class="ui-btn-right"></a>
    <% } %>
  '''

  render: ->
    @model.right_id_attr = if @model.right_id?
      "id='#{@model.right_id}'" 
    else
      ""
    @model.left_id_attr = if @model.left_id?
      "id='#{@model.left_id}'" 
    else
      ""

    @$el.html @template(@model)
    this

class App.Views.FooterRenderer extends Backbone.View
  template: _.template '''
    <div data-role="footer" class="ui-bar"  data-position="fixed">

    <% if (typeof list_id != 'undefined') { %>
      <a id='button-play' href="#playing/<%= type %>/<%= list_id %>/<%= track_id %>" data-theme='b'>Play!</a>
    <% } %>

    <% if (typeof play_external != 'undefined' && play_external ) { %>
      <a href="<%= play_external %>" data-theme='b' target='_blank'>Play!</a>
    <% } %>

    <% if (typeof export_media != 'undefined' && export_media ) { %>
      <a id='button-export' href="#" data-theme='b'>Export</a>
    <% } %>

    <% if (typeof playing != 'undefined' && playing) { %>
      <a href="#playing" data-theme='b' style="float:right;margin-right:27px;">Now Playing...</a>
    <% } %>
    </div>
  '''

  render: ->

    @$el.html @template(@model)
    this

