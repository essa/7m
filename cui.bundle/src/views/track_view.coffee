

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
      <div id='items' class='ui-grid-a'>
        <div style='font-size: small' class='ui-block-a'>Rateing:</div>
        <div class='ui-block-b'>
          <div class='rateit' data-rateit-step='1.0' />
        </div>
        <div style='font-size: small' class='ui-block-a'>name:</div>
        <div class='ui-block-b'><a href='<%= name_search %>'><%= name %></a></div>
        <div style='font-size: small' class='ui-block-a'>album:</div>
        <div class='ui-block-b'><a href='<%= album_search %>'><%= album %></a></div>
        <div style='font-size: small' class='ui-block-a'>artist:</div>
        <div class='ui-block-b'><a href='<%= artist_search %>'><%= artist %></a></div>
        <% for(i = 0; i< props.length;i++) { %>
          <div style='font-size: small' class='ui-block-a'><%= props[i][0] %>:</div>
          <div class='ui-block-b'><%= props[i][1] %></div>
        <% } %>
      </div>
    </div>
  ''' 

  render: ->
    console.log 'TrackView.render', @model.get('status')
    attrs = @model.toJSON()
    attrs.type = @type
    attrs.playlist_id = @playlist.id
    attrs.bookmark = @hhmmss(attrs.bookmark || 0)
    attrs.pause_at = @hhmmss(attrs.pause_at || attrs.duration || 0)
    attrs.name = @model.get('name')
    attrs.name_search = "#search/#{@model.get('name')}"
    attrs.album = @model.get('album')
    attrs.album_search = "#search/album: #{@model.get('album')}"
    attrs.artist = @model.get('artist')
    attrs.artist_search = "#search/artist: #{@model.get('artist')}"
    attrs.props = [
      # [ 'name', @model.get('name') ],
      # [ 'artist', @model.get('artist') ],
      # [ 'album', @model.get('album') ],
      [ 'id', @model.id ],
      [ 'duration', @hhmmss @model.get('duration') ],
      [ 'bookmark', @hhmmss @model.get('bookmark') ],
      [ 'pause_at', @hhmmss @model.get('pause_at') ],
      [ 'playedCount', @model.get('playedCount') ],
      [ 'playedDate', @model.get('playedDate') ],
      [ 'original bitrate', @model.get('bitRate') ],
    ]
    @$el.html @template(attrs)
    $('.rateit').rateit
      value: parseInt(@model.get('rating'))/20

    @renderHeader()
    @renderFooter() 
    setTimeout =>
      @$el.trigger("pagecreate")
    , 10

    this

  renderHeader: ->
    $header = @$el.find('div[data-role="header"]')


    if @type == 'search'
      left_href = "search/#{encodeURI @playlist.get('word')}"
    else
      left_href = "#{@type}/#{@playlist.id}"

    r = new App.Views.HeaderRenderer
      el: $header
      model:
        left_icon: 'arrow-l'
        left_href: left_href
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
        play_text: if @type == 'search' then 'Request' else undefined 

    @$el.append footerRenderer.render().el

  hhmmss: (s)->
      return '' unless s
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

  rated: (e, value)->
    console.log 'rated', value
    @model.save
      rating: value*20
    ,
      patch: true

  reset_rate: (e)->
    @rated(e, 0)


  close: ->
    console.log 'TrackView#close'
    @stopListening()
    @undelegateEvents() 
    @model.off 'change', @render

class App.Views.TrackViewForEmbendedPlayer extends App.Views.TrackView
  events:
    "tap #button-play" : "play"
    "taphold #button-play" : "show_play_panel"
    "popupafterclose #track-play-panel": "on_close_play_panel"
    "rated .rateit": "rated"
    "reset .rateit": "reset_rate"

  play: (e)->
    e.preventDefault()
    if @type == 'search'
      app = @app
      playlist = @playlist
      @model.addToQueue()
      setTimeout ->
        app.router.navigate "search/#{encodeURI playlist.get('word')}",
          trigger: true
      , 1000
      return
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


class App.Views.TrackViewForExternalPlayer extends App.Views.TrackView
  events:
    "tap #button-play" : "show_play_panel"
    "popupafterclose #track-play-panel": "on_close_play_panel"
    "rated .rateit": "rated"
    "reset .rateit": "reset_rate"

  show_play_panel: (e)->
    e.preventDefault()
    if @type == 'search'
      @model.addToQueue()
      setTimeout ->
        app.router.navigate "search/#{encodeURI playlist.get('word')}",
          trigger: true
      , 1000
      return
    console.log 'trackView#show_play_panel'
    $('#popup-div').html '<div data-role="popup" id="track-play-panel" style="padding: 15px;" />'
    $panel = $('#track-play-panel')
    @panel = new Panel
      el: $panel
      model: @model
      app: @app

    @panel.show()

  on_close_play_panel: (e)->
    @panel.close()
    $('#popup-div').html ''
    $('.ui-popup-screen').remove()
    $('.ui-popup-container').remove()
    @panel = null

  class Panel extends Backbone.View

    template: _.template '''
      <div>
        <a href="<%= play_track_link %>" target="_blank" data-role="button" data-theme='b'>Play only this track</a>
      </div>
      <hr />
      <div>
        <a href="<%= play_track_full_link %>" target="_blank" data-role="button" data-theme='b'>Play this track full duration</a>
      </div>
    '''
    initialize: (options)->
      super(options)
      @app = options.app

    render: ->
      bps = @app.config.bps()
      start = parseInt(@model.get('bookmark'))
      pause = @model.get('pause_at')
      play_track_link = @model.mediaUrl(bps: bps, start: start, pause: pause)
      play_track_full_link = @model.mediaUrl(bps: bps)
      @$el.html @template
        play_track_link: play_track_link
        play_track_full_link: play_track_full_link

      @$el.trigger("create")
      this

    show: ->
      @render()
      console.log @el
      @$el.popup()
      @$el.popup "open",
        transition: 'flip'

