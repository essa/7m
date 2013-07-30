

class App.Views.PlaylistView extends Backbone.View
  seq: 2
  transition: 'slide'
  events:
    "tap #button-play" : "play"
    "taphold #button-play" : "show_play_panel"
    "tap #button-list-refresh" : "show_refresh_panel"
    "taphold #button-list-refresh" : "sync_list"
    "popupafterclose #refresh-panel": "on_close_refresh_panel"
    "popupafterclose #play-panel": "on_close_play_panel"

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
      <div id='popup-refresh-div' />
      <div id='popup-play-div' />
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
    if @type == 'search'
      left_href = "search/#{@model.get('word')}"
    else
      left_href = ''
    r = new App.Views.HeaderRenderer
      el: $header
      model:
        left_icon: 'arrow-l'
        left_href: left_href 
        title: @model.get('name')
        right_icon: 'refresh'
        right_href: ''
        right_id: 'button-list-refresh'

    r.render()

  renderFooter: ->
    r = new App.Views.FooterRenderer
      model:
        playing: @app.hasTrackPlaying()

    @$el.append r.render().el

  sync_list: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    return if @refreshPanel
    console.log 'refresh list'
    @model.tracks.fetch()

  export_media: (e)->
    e.preventDefault()
    @model.prepareMedia
      export: true
      bps: @app.config.bps()
      success: =>
        Env.alert('export completed')
        @model.tracks.fetch()
      error: =>
        alert('media export error')

  close: ->
    @undelegateEvents()
    @stopListening()
    @model.off 'sync', @render, this

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
    e.stopImmediatePropagation()
    $.mobile.popup.active = undefined # sometimes popup seems not to close normally

    console.log 'PlaylistView#show_refresh_panel'
    $('#popup-refresh-div').html '<div data-role="popup" id="refresh-panel" style="padding: 15px;" />'
    $panel = $('#refresh-panel')
    @refreshPanel = new RefreshPanel
      el: $panel
      model: @model
      app: @app
      type: @type
      parent: this

    @refreshPanel.show()

  on_close_refresh_panel: (e)->
    @refreshPanel.close() if @refreshPanel
    $('#popup-refresh-div').html ''
    # $('.ui-popup-screen').remove()
    # $('.ui-popup-container').remove()
    @refreshPanel = null

  show_play_panel: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    $.mobile.popup.active = undefined # sometimes popup seems not to close normally

    console.log 'PlaylistView#show_play_panel'
    $('#popup-play-div').html '<div data-role="popup" id="play-panel" style="padding: 15px;" />'
    $panel = $('#play-panel')
    @playPanel = new PlayPanel
      el: $panel
      model: @model
      app: @app
      type: @type
      parent: this

    @playPanel.show()

  on_close_play_panel: (e)->
    @playPanel.close() if @playPanel
    $('#popup-play-div').html ''
    @playPanel = null

  playlist_address: (bps)->
    m3u8 = "/#{@type}/#{@model.id}.m3u"
    m3u8 += "?bps=#{bps}" if bps?
    m3u8

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

  class RefreshPanel extends Backbone.View
    events:
      "tap #button-list-sync" : "sync"
      "tap #button-list-refresh2" : "refresh"
      "tap #button-list-clear-and-refresh" : "clear_and_refresh"
      "tap #button-list-refresh-and-play" : "refresh_and_play"


    template: _.template '''
      <div>
        <a data-role="button" id='button-list-sync' data-theme='b'>Sync</a>
        <p>sync list with server</p>
      </div>
      <hr />
      <% if (show_refresh) { %>
        <div>
          <a data-role="button" id='button-list-refresh2' data-theme='b'>Refresh</a>
          <p>clear played and get new tracks</p>
        </div>
        <hr />
      <% } %>
      <div>
        <a data-role="button" id='button-list-clear-and-refresh' data-theme='b'>Clear and Refresh</a>
        <p>clear all tracks and get new</p>
      </div>
      <hr />
      <div>
        <a data-role="button" id='button-list-refresh-and-play' data-theme='b'>Refresh and Play</a>
        <p>clear all tracks and get and play new</p>
      </div>
    '''
    initialize: (options)->
      super(options)
      @app = options.app
      @parent = options.parent

    render: ->
      @$el.html @template 
        show_refresh: @parent.type == 'programs'
      @$el.trigger("create")
      this

    show: ->
      console.log 'RefreshPanel#show'
      @render()
      @$el.popup
        positionTo: 'window'
      @$el.popup "open",
        transition: 'flip'
      @$el.show()

    sync: (e)->
      console.log 'sync'
      e.preventDefault()
      @model.tracks.fetch()
      @closePanel()

    refresh: (e)->
      e.preventDefault()
      @model.refresh()
      @closePanel()

    clear_and_refresh: (e)->
      e.preventDefault()
      @model.refresh(clear: true)
      @closePanel()

    refresh_and_play: (e)->
      e.preventDefault()
      @model.refresh
        clear: true
        success: =>
          @app.trigger 'playRequest', @model
          @closePanel()

    closePanel: ->
      @$el.popup 'close'
      $.mobile.popup.active = undefined # popup('close') seems not to close normally

    close: ->
      console.log 'PlaylistView::RefreshPanel#close'
      @stopListening()
      @undelegateEvents() 

  class PlayPanel extends Backbone.View
    events:
      "tap #button-play-play" : "play"
      "tap #button-play-export" : "export"

    template: _.template '''
      <div>
        <a data-role="button" id='button-play-play' data-theme='b'>Play</a>
        <p>play this list</p>
      </div>
      <hr />
      <div>
        <a data-role="button" id='button-play-export' data-theme='b'>Export to Dropbox</a>
        <p>export this list to Dropbox</p>
      </div>
      <hr />
      <div>
        <a href='<%= pl_addr %>'>Link to this playlist</a>
        <p>register it to your net radio player</p>
      </div>
    '''

    initialize: (options)->
      super(options)
      @app = options.app
      @parent = options.parent

    render: ->
      @$el.html @template
       pl_addr: @parent.playlist_address()
      @$el.trigger("create")
      this

    show: ->
      @render()
      console.log @el
      @$el.popup()
      @$el.popup "open",
        transition: 'flip'

    play: (e)->
      @closePanel()
      @parent.play(e)

    export: (e)->
      @parent.export_media(e)
      @closePanel()

    closePanel: ->
      @$el.popup 'close'
      $.mobile.popup.active = undefined # popup('close') seems not to close normally

    close: ->
      console.log 'PlaylistView::PlayPanel#close'
      @stopListening()
      @undelegateEvents() 

class App.Views.PlaylistViewForEmbendedPlayer extends App.Views.PlaylistView
  play: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    return if @playPanel

    console.log 'play'
    href="playing/#{@type}/#{@model.id}"
    @app.router.navigate(href, trigger: true)

class App.Views.PlaylistViewForExternalPlayer extends App.Views.PlaylistView
  play: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    return if @playPanel

    console.log 'play'
    bps = @app.config.bps()
    pl_addr = @playlist_address(bps)
    console.log pl_addr
    Env.gotoLocation(pl_addr)

