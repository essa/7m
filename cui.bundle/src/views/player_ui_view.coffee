

class App.Views.PlayerUIView extends Backbone.View
  seq: 3
  transition: 'slideup'

  initialize: (options)->
    super(options)
    @softPauseTime = 2.0
    @playing = true
    @model.on 'timeupdate', @onTimeUpdate, @
    @onTimeUpdate(0)
    @model.on 'change', @render, @

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
      <div style='text-align: center'>
        <div style='font-size: small'>
          <span class='artist'><%= artist %></span>
        </div>
        <div style='font-size: xx-large;height: 60px;white-space: nowrap;'>
          <span class='name'><%= name %></span>
        </div>
        <div style='font-size: small'>
          <span class='album'><%= album %></span>
        </div>
        <div style='font-size: small'>
          <span class='time-range'><%= bookmark %>-><%= pause_at %></span>
        </div>
        <div style='font-size: small'>
          <span class='currentTime'><%= '00:00:00/00:00:00' %></span>
        </div>
      </div>
      <div style='text-align: center; margin: 10px;'>
        <img id="button-skip30sec" src='./images/Fast-forward64.png' /> 
        <% if (status == App.Status.PLAYING) { %>
          <img id="button-pause" src='./images/Pause64.png' />
        <% } else { %>
          <img id="button-continue" src='./images/Play64.png' /> 
        <% } %>
        <img id="button-skip" src='./images/Skip-forward64.png' /> 
        <img id="button-stop" src='./images/Stop64.png' /> 
      </div>
      <div style='text-align: center; margin: 10px;'>
        <a href='<%= track_link %>'>show track infomation</a>
      </div>
    </div>
  ''' 

  events:
    "click #button-pause" : "pause"
    "click #button-continue" : "continue"
    "click #button-stop" : "stop"
    "click #button-skip" : "skip"
    "click #button-skip30sec" : "skip30sec"

  render: ->
    console.log 'PlayerUIView#render'
    @showVolumeSlider()

    attrs = @model.toJSON()
    attrs.bookmark = @hhmmss(attrs.bookmark || 0)
    attrs.pause_at = @hhmmss(attrs.pause_at || attrs.duration || 0)
    attrs.track_link =  "##{@model.list.type}/#{@model.list.id}/tracks/#{@model.track.id}" if @model.list and @model.track
    @$el.html @template(attrs)
    # $content = @$el.find('div[data-role="content"]')
    # $content.trigger 'create'
    @render_header()
    if @model.get('status') == App.Status.PLAYING
      $('.name').marquee
        width: '100%'

    # unless @$el.hasClass('ui-page-active')
    setTimeout =>
      @onTimeUpdate(@currentSecond)
      @$el.trigger "pagecreate" 
    , 1

    this

  render_header: ->
    $header = @$el.find('div[data-role="header"]')
    list = @model.list
    back_href = "#{list.type}/#{list.id}" if list
    console.log "rendering playlists header #{@model.get('path')}"
    r = new App.Views.HeaderRenderer
      el: $header
      model:
        left_icon: 'arrow-l'
        left_href: back_href
        title: @model.status()
    r.render()

  pause: ->
    App.trigger 'pauseRequest'

  continue: ->
    App.trigger 'continueRequest'

  stop: ->
    App.trigger 'stopRequest'

  skip: ->
    App.trigger 'skipRequest'
    
  skip30sec: ->
    if @currentSecond?
      App.trigger 'seekRequest', parseInt(@currentSecond) + 30 
    else
      App.trigger 'seekRequest', 30 

  onTimeUpdate: (pos)->
    # console.log 'PlayerUIView#onTimeUpdate', pos
    pos = 0 unless parseInt(pos) > 0

    @currentSecond = pos 
    @currentTime = "#{@hhmmss(pos)}/#{@hhmmss(@model.get('duration'))}"
    @$el.find('.currentTime').html @currentTime

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
    console.log 'PlayerUIView#close'
    @hideVolumeSlider()
    @stopListening()
    @undelegateEvents() 
    @model.off 'change', @render, @
    @model.off 'timeupdate', @onTimeUpdate, @

  showVolumeSlider: ->
    @hideVolumeSlider()
    if window.plugins?
      unless @vsVisible
        # console.log 'show volumeSlider'
        vs = window.plugins.volumeSlider
        vs?.createVolumeSlider(10,450,300,30)
        vs?.showVolumeSlider()
        # console.log 'show volumeSlider end'
      @vsVisible = true

  hideVolumeSlider: ->
    if window.plugins?
      # console.log 'hide volumeSlider'
      vs = window.plugins.volumeSlider
      vs?.hideVolumeSlider()
      @vsVisible = false
      # console.log 'hide volumeSlider end'
