
class App.Views.SearchView extends Backbone.View
  seq: 2
  transition: 'slideup'
  events:
    "keyup #search-word" : "search"

  template: _.template '''
    <div data-role="header">
      <a href='#' data-role='button' data-icon='arrow-l' data-iconpos="notext"></a>
      <h1 id='config-header'>Search and Request</h1>
    </div>
    <div data-role="content">
      <div data-role='fieldcontain'>
        <label for="search-basic">Search Input:</label>
        <input type="search" name="search" id="search-word" value="<%= word %>" />
        <% if (word.length == 0) { %>
          <p id='type-message'>type song name, artist name or album to search tracks</p>
        <% } %>
      </div>
      <div>
        <ul data-role='listview' id='search-result'>
        </ul>
      </div>
    </div>
  '''

  initialize: (options)->
    super(options)
    @app = options.app
    @model.on 'sync', @render_result, @
    @model.tracks.fetch()

  render_header: ->
    $header = @$el.find('div[data-role="header"]')
    if $header.find('h1').size() == 0
      console.log 'rendering playlists header'
      header_view = new App.Views.HeaderView
        el: $header
        model:
          right_icon: 'gear'
          right_href: 'config'
          title: 'SevenMinutes'
      header_view.render()

  render: ->
    html =  @template 
      word: @model.get('word') || ''
      tracks: @model.tracks.toJSON()
    @$el.html html

    @render_header()
    this

  search: (e)->
    q = @$('#search-word').val()
    if q.length >= 3 
      clearTimeout(@searchTimer) if @searchTimer
      @searchTimer = setTimeout =>
        console.log q
        @model.set word: q
        @model.tracks.fetch()
        @app.router.navigate("#search/#{q}", trigger: false)
      , 1000

  render_result: ->
    $('#type-message').hide() if @model.tracks.length > 0
    $ul = @$('#search-result')
    $ul.html ''
    @model.tracks.each (t)=>
      href = "#search/#{@model.get('word')}/tracks/#{t.id}"
      console.log href
      $ul.append "<li><a href='#{href}'>#{t.get('name')}</a></li>"
    $ul.listview('refresh')


  close: ->
    @model.off 'change', @render_result, @
    @undelegateEvents()
    @stopListening()
