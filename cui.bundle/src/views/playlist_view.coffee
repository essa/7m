

class App.Views.PlaylistView extends Backbone.View
  seq: 2
  transition: 'slide'
  events:
    "tap #button-play" : "play"
    "tap #button-export" : "export_media"
    "tap #button-show-list-panel" : "show_panel"
    "tap #button-list-refresh" : "refresh_list"
    "taphold #button-list-refresh" : "show_refresh_panel"
    "tap #button-list-create-audio" : "create_audio"
    "tap #button-record-played" : "record_played"
    "popupafterclose #refresh-panel": "on_close_refresh_panel"

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
      <div id='popup-refresh-div' />
      <div data-role="popup" id="list-panel" style='padding: 15px;'>
      </div>
      <div>
        <ul id='tracks-ul'  data-role="listview"></ul>
      </div>
    </div>
  '''

  initialize: (options)->
    super(options)
    @app = options.app
    @type = options.type
    @hasFlash = options.hasFlash
    @model.on 'sync', @render, this

  render: ->
    console.log 'render'
    @$el.html @template()
    $content = @$el.find('div[data-role="content"]')

    $ul = $content.find('ul')
    $ul.empty()
    @model.tracks.each (t)=>
      itemView = new Item
        model: t
        type: @type
      itemView.playlist = @model
      $ul.append itemView.render().$el
      
    @renderHeader()
    @renderFooter() 
    setTimeout =>
      console.log 'trigger pagecreate'
      @$el.trigger 'pagecreate'
    , 1

    this

  renderHeader: ->
    $header = @$el.find('div[data-role="header"]')
    r = new App.Views.HeaderRenderer
      el: $header
      model:
        left_icon: 'arrow-l'
        left_href: ''
        title: @model.get('name')
        right_icon: 'refresh'
        right_href: ''
        right_id: 'button-list-refresh'

    r.render()

  play: (e)->
    console.log 'play', @hasFlash
    unless @hasFlash
      @show_panel(e)


  refresh_list: (e)->
    e.preventDefault()
    console.log 'refresh list'
    @model.refresh
      error: ->
        alert('refresh error!')

  export_media: (e)->
    e.preventDefault()
    @model.prepareMedia
      export: true
      bps: @app.config.bps()
      success: =>
        alert('export completed')
        @model.refresh
          success: =>
            @render()
      error: =>
        alert('media export error')

  close: ->
    @undelegateEvents()
    @stopListening()
    @model.off 'sync', @render, this

  class Item extends Backbone.View
    initialize: (options)->
      @type = options.type
    tagName: "li"
    template: _.template '''
      <a href="#<%= type %>/<%= playlist_id %>/tracks/<%= id %>"><%= name %></a>
      <div style='margin-left: 10%; width: 70%; margin-bottom: 2px;border: solid 1px; color: #408040;'>
        <div style='<%= this.barStyle() %>'</div>
      </div>
    '''

    render: ->
      $('.ui-popup-screen').remove()
      $('.ui-popup-container').remove()
      html = @template
        id: @model.id
        playlist_id: @playlist.id
        name: @model.get('name')
        type: @type
        played: @model.get('played')
      @$el.html html
      theme = if parseInt(@model.get('played')) > 0
        'e'
      else
        'c'
      @$el.attr('data-theme', theme)
      this

    barStyle: ->
      duration = @model.get('duration')
      bookmark = @model.get('bookmark') || 0
      pause_at = @model.get('pause_at') || duration
      start = parseInt(bookmark*100.0/duration)
      width  = parseInt((pause_at-bookmark)*100.0/duration)
      """
      margin-left: #{start}%;
      width: #{width}%;
      height: 3px;
      aling: center;
      background-color: #6080e0;
      """

  show_panel: (e)->
    e.preventDefault()
    console.log 'show panel', 
    $panel = $('#list-panel')
    @panel = new Panel
      el: $panel
      model: @model
      bps: @app.config.bps()

    @panel.createAudio()
    @panel.show()
      

  show_refresh_panel: (e)->
    e.preventDefault()
    console.log 'PlaylistView#show_refresh_panel'
    $('#popup-refresh-div').html '<div data-role="popup" id="refresh-panel" style="padding: 15px;" />'
    $panel = $('#refresh-panel')
    @refreshPanel = new RefreshPanel
      el: $panel
      model: @model
      app: @app
      type: @type

    @refreshPanel.show()

  on_close_refresh_panel: (e)->
    @refreshPanel.close() if @refreshPanel
    $('#popup-refresh-div').html ''
    $('.ui-popup-screen').remove()
    $('.ui-popup-container').remove()
    @refreshPanel = null


  class RefreshPanel extends Backbone.View
    events:
      "tap #button-list-refresh2" : "refresh"
      "tap #button-list-clear-and-refresh" : "clear_and_refresh"
      "tap #button-list-refresh-and-play" : "refresh_and_play"


    template: _.template '''
      <div>
        <a data-role="button" id='button-list-refresh2' data-theme='b'>Refresh</a>
        <p>clear played and get new tracks</p>
      </div>
      <hr />
      <div>
        <a data-role="button" id='button-list-clear-and-refresh' data-theme='b'>Clear and Refresh</a>
        <p>clear all tracks and get new</p>
      </div>
      <hr />
      <div>
        <a data-role="button" id='button-list-refresh-and-play' data-theme='b'>Refresh and Play</a>
        <p>clear all tracks and get and play new</p>
      </div>
      <hr />
    '''
    initialize: (options)->
      super(options)
      @app = options.app

    render: ->
      @$el.html @template {}
      @$el.trigger("create")
      this

    show: ->
      @render()
      console.log @el
      @$el.popup()
      @$el.popup "open",
        transition: 'flip'

    refresh: (e)->
      e.preventDefault()
      @model.refresh()
      @$el.popup 'close'

    clear_and_refresh: (e)->
      e.preventDefault()
      @model.refresh(clear: true)
      @$el.popup 'close'

    refresh_and_play: (e)->
      e.preventDefault()
      @app.trigger 'playRequest', @model
      @$el.popup 'close'

    close: ->
      console.log 'PlaylistView::RefreshPanel#close'
      @stopListening()
      @undelegateEvents() 

class App.Views.PlaylistViewForEmbendedPlayer extends App.Views.PlaylistView
  renderFooter: ->
    firstTrack = @model.tracks.at(0)
    r = new App.Views.FooterRenderer
      model:
        playing: @app.hasTrackPlaying()
        type: @type
        list_id: @model.id
        track_id: firstTrack?.id
        export_media: true

    @$el.append r.render().el


class App.Views.PlaylistViewForExternalPlayer extends App.Views.PlaylistView
  class Panel extends Backbone.View
    events:
      "click #button-record-played" : "record_played"

    template: _.template '''
      <% if (mediaPrepared) { %>
        <div>
          <span id="list-stream">
            <a href="<%= mediaUrl %>" target="_blank" data-role="button"> Play it with external player</a>
          </span>
          <div style='font-size: small'>
            A new tab will open and combined audio stream will be played
          </div>
        </div>
        <hr />
        <div>
          <div style='font-size: small'>
            After playing it, you can ....  
          </div>
          <a href='#' id='button-record-played' data-role="button">
            Save bookmark and palyedDate to iTunes
          </a>
        </div>
      <% } else { %>
        <div>
          <p>Preparing media. Just a moment please.</p>
        </div>
      <% } %>
    '''
    initialize: (options)->
      super(options)
      @bps = options.bps

    render: ->
      @$el.html @template
        mediaPrepared: @mediaPrepared
        mediaUrl: @model.mediaUrl(bps: @bps)
      @$el.trigger("create")
      this

    show: ->
      @render()
      @$el.popup "open",
        transition: 'flip'

    createAudio: ->
      @mediaPrepared = @model.mediaPrepared(bps: @bps)
      unless @mediaPrepared
        console.log @model.prepareMedia
        @model.prepareMedia
          bps: @bps
          success: =>
            @mediaPrepared = true
            @render()
            alert('create completed')
          error: =>
            alert('media creation error')

    record_played: (e)->
      e.preventDefault()
      @model.recordPlayed
        success: =>
          @model.refresh
            success: =>
              alert('record success')
        error: ->
          alert('error')
          Env.reset()

  initialize: (options)->
    super(options)
    
  renderFooter: ->
    firstTrack = @model.tracks.at(0)
    m3u8 = "/#{@type}/#{@model.id}.m3u8"
    bps = @app.config.bps()
    m3u8 += "?bps=#{bps}" if bps?
    r = new App.Views.FooterRenderer
      model:
        play_external: m3u8
        export_media: true

    @$el.append r.render().el
