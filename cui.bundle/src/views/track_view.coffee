

class App.Views.TrackView extends Backbone.View
  seq: 3
  transition: 'slide'

  initialize: (options)->
    super(options)
    console.log options
    @app = options.app
    @type = options.type
    @hasPlayer = options.hasPlayer
    @playlist = options.playlist
    @model.on 'change', @render, @

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
      <div id='popup-div' />
      <div style='text-align: center'>
        <div style='font-size: small'>
          <span class='artist'><%= artist %></span>
        </div>
        <div style='font-size: xx-large'>
          <span class='name'><%= name %></span>
        </div>
        <div style='font-size: small'>
          <span class='album'><%= album %></span>
        </div>
        <div style='font-size: small'>
          <span class='time-range'><%= bookmark %>-><%= pause_at %></span>
        </div>
      </div>
      <div style='text-align: center'>
        <span href="#" id="button-skip30sec" data-role="button" data-inline='true'>+30 sec</span>
      </div>
    </div>
  ''' 
  events:
    "tap #button-play" : "play"
    "taphold #button-play" : "show_play_panel"
    "popupafterclose #track-play-panel": "on_close_play_panel"

  render: ->
    console.log 'TrackView.render', @model.get('status')
    attrs = @model.toJSON()
    console.log attrs
    attrs.type = @type
    attrs.playlist_id = @playlist.id
    attrs.bookmark = @hhmmss(attrs.bookmark || 0)
    attrs.pause_at = @hhmmss(attrs.pause_at || attrs.duration || 0)
    @$el.html @template(attrs)
    @renderHeader()
    @renderFooter() 

    this

  renderHeader: ->
    $header = @$el.find('div[data-role="header"]')
    r = new App.Views.HeaderRenderer
      el: $header
      model:
        left_icon: 'arrow-l'
        left_href: "#{@type}/#{@playlist.id}"
        title: @model.get('name')
    r.render()

  renderFooter: ->
    console.log 'rederFooter'
    footerRenderer = new App.Views.FooterRenderer
      model:
        type: @type
        list_id: @playlist.id
        track_id: @model.id
        playing: @app.hasTrackPlaying()

    @$el.append footerRenderer.render().el

  hhmmss: (s)->
      sec_numb = parseInt(s, 10)
      hours = Math.floor(sec_numb / 3600)
      minutes = Math.floor((sec_numb - (hours * 3600)) / 60)
      seconds = sec_numb - (hours * 3600) - (minutes * 60)
      if (hours   < 10) 
        hours   = "0"+hours
      if (minutes < 10) 
        minutes = "0"+minutes
      if (seconds < 10) 
        seconds = "0"+seconds
      hours+':'+minutes+':'+seconds

  close: ->
    console.log 'TrackView#close'
    @stopListening()
    @undelegateEvents() 
    @model.off 'change', @render

class App.Views.TrackViewForEmbendedPlayer extends App.Views.TrackView
  class Panel extends Backbone.View
    events:
      "tap #button-play-track" : "play_track"
      "tap #button-play-track-full" : "play_track_full"

    template: _.template '''
      <div>
        <a href="#" id='button-play-track' data-role="button" data-theme='b'>Play only this track</a>
      </div>
      <hr />
      <div>
        <a href="#" id='button-play-track-full' data-role="button" data-theme='b'>Play this track full duration</a>
      </div>
    '''
    initialize: (options)->
      super(options)
      @app = options.app
      @type = options.type
      @playlist = options.playlist

    render: ->
      track_href = "#playing/#{@type}/#{@playlist_id}/#{@model.id}"
      @$el.html @template
        track_href: track_href 

      @$el.trigger("create")
      this

    show: ->
      @render()
      console.log @el
      @$el.popup()
      @$el.popup "open",
        transition: 'flip'

    play_track: (e, options={})->
      e.preventDefault()
      console.log 'trackView#play_track'
      @app.trigger 'playRequest', null, @model, options
      @$el.popup 'close'
      @app.router.navigate('#playing', trigger: true)

    play_track_full: (e)->
      @play_track(e, full: true)
      @$el.popup 'close'

    close: ->
      console.log 'TrackView::Panel#close'
      @stopListening()
      @undelegateEvents() 

  play: (e)->
    e.preventDefault()
    return if @panel
    @app.trigger 'playRequest', @playlist, @model
    @app.router.navigate('#playing', trigger: true)

  show_play_panel: (e)->
    e.preventDefault()
    console.log 'trackView#show_play_panel'
    $('#popup-div').html '<div data-role="popup" id="track-play-panel" style="padding: 15px;" />'
    $panel = $('#track-play-panel')
    @panel = new Panel
      el: $panel
      model: @model
      app: @app
      type: @type
      playlist_id: @playlist_id

    @panel.show()

  on_close_play_panel: (e)->
    @panel.close()
    $('#popup-div').html ''
    $('.ui-popup-screen').remove()
    $('.ui-popup-container').remove()
    @panel = null


