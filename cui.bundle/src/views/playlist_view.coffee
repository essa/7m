

class App.Views.PlaylistView extends Backbone.View
  seq: 2
  transition: 'slide'
  events:
    "click #button-play" : "play"
    "click #button-export" : "export_media"
    "click #button-show-list-panel" : "show_panel"
    "click #button-list-refresh" : "refresh_list"
    "click #button-list-create-audio" : "create_audio"
    "click #button-record-played" : "record_played"

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
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
              window.location.reload()
        error: ->
          alert('error')
          window.location.reload()

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
      


