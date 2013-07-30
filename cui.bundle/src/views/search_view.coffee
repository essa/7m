
class App.Views.SearchView extends Backbone.View
  seq: 2
  transition: 'slideup'
  events:
    "keyup #search-word" : "search"

  template: _.template '''
    <div data-role="header">
      <h1 id='config-header'>Search</h1>
    </div>
    <div data-role="content">
      <div data-role='fieldcontain'>
        <label for="search-basic">Search Input:</label>
        <input type="search" name="search" id="search-word" value="<%= word %>" />
      </div>
      <div>
        <ul data-role='listview' id='search-result'>
          <li>aaaa</li>
        <ul>
      </div>
    </div>
  '''

  initialize: (options)->
    super(options)
    @model.on 'change', @render_result, @

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
      word: @model.get('word')
      tracks: @model.tracks.toJSON()
    @$el.html html

    @render_header()
    this

  search: (e)->
    q = @$('#search-word').val()
    if q.length >= 3 
      console.log q
      @model.set word: q
      @model.tracks.fetch()

  render_result: ->
    $ul = @$('#search-result')
    $ul.html ''
    @model.tracks.each (t)->
      console.log t
      $ul.append "<li><a href='#{t.id}'>#{t.get('name')}</a></li>"
    $ul.listview('refresh')


  close: ->
    @model.off 'change', @render_result, @
    @undelegateEvents()
    @stopListening()
