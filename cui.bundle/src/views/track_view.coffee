

class App.Views.TrackView extends Backbone.View
  seq: 3
  transition: 'slide'

  initialize: (options)->
    super(options)
    @app = options.app
    @type = options.type
    @hasPlayer = options.hasPlayer
    @playlist_id = options.playlist_id
    @model.on 'change', @render, @

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
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
    "click #button-pause" : "pause"

  render: ->
    console.log 'TrackView.render', @model.get('status')
    attrs = @model.toJSON()
    attrs.type = @type
    attrs.playlist_id = @playlist_id
    attrs.bookmark = @hhmmss(attrs.bookmark || 0)
    attrs.pause_at = @hhmmss(attrs.pause_at || attrs.duration || 0)
    @$el.html @template(attrs)
    @renderHeader()
    @renderFooter() if @hasPlayer

    this

  renderHeader: ->
    $header = @$el.find('div[data-role="header"]')
    r = new App.Views.HeaderRenderer
      el: $header
      model:
        left_icon: 'arrow-l'
        left_href: "#{@type}/#{@playlist_id}"
        title: @model.get('name')
    r.render()

  renderFooter: ->
    footerRenderer = new App.Views.FooterRenderer
      model:
        type: @type
        list_id: @playlist_id
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

