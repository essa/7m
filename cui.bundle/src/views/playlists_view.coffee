
class App.Views.PlaylistsView extends Backbone.View
  seq: 1

  initialize: (options)->
    super(options)
    @app = options.app
    @programs = options.programs
    @playlists = options.playlists
    @hasFlash = options.hasFlash

    @programs.on "sync", @updateScreeen, @ if @programs
    @playlists.on "sync", @updateScreen, @ if @playlists 

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
      <div data-role="collapsible-set" data-content-theme="d" id="set">
        <div data-role="collapsible" id="set1" data-collapsed="false">
          <h3>My Library</h2>
          <ul id='search-ul'  data-role="listview">
            <li><a href='#search'>search</a></li>
          <ul>
        </div>
        <div data-role="collapsible" id="set1" data-collapsed="true">
          <h3>My Radio Programs</h2>
          <ul id='programs-ul'  data-role="listview"/>
        </div>
        <div data-role="collapsible" id="set1" data-collapsed="true">
          <h3>My Playlists</h2>
          <ul id='playlists-ul'  data-role="listview"/>
        </div>
      </div>
    </div>
    '''

  render: ->
    @$el.html @template()
    return unless @programs and @playlists

    $content = @$el.find('div[data-role="content"]')
    $ul1 = @$el.find('ul#programs-ul')
    
    @programs.each (pl)->
      itemView = new Item
        model: 
          type: 'programs'
          id: pl.id 
          name: pl.get('name')
      $ul1.append itemView.render().$el

    $ul2 = @$el.find('ul#playlists-ul')
    $ul3 = @$el.find('ul#search-ul')
    @playlists.each (pl)->
      unless pl.get('queue')
        itemView = new Item
          model: 
            type: 'playlists'
            id: pl.id 
            name: pl.get('name')
        $ul2.append itemView.render().$el
      else
        itemView = new Item
          model: 
            type: 'playlists'
            id: pl.id 
            name: 'Playing queue'
        $ul3.append itemView.render().$el

    @renderHeader()
    @renderFooter() 

    this

  renderHeader: ->
    $header = @$el.find('div[data-role="header"]')
    headerRenderer = new App.Views.HeaderRenderer
      el: $header
      model:
        right_icon: 'gear'
        right_href: 'config'
        title: 'SevenMinutes'
    headerRenderer.render()

  renderFooter: ->
    return unless @app.hasTrackPlaying()
    r = new App.Views.FooterRenderer
      model:
        playing: @app.hasTrackPlaying()

    @$el.append r.render().el

  @updateScreen: ->
    @render()
    setTimeout ->
      @$el.trigger 'pagecreate'
    , 1

  close: ->
    console.log @programs
    @undelegateEvents()
    @stopListening()
    @programs.off 'sync', @updateScreen, this if @programs
    @playlists.off 'sync', @updateScreen, this if @playlists

  class Item extends Backbone.View
    tagName: "li"
    template: _.template('<a href="#<%= type %>/<%= id %>"><%= name %></a>')
    render: ->
      html = @template(@model)
      @$el.html html
      this
  App.Views.PlaylistsItemView = Item

class App.Views.PlaylistsViewOld extends App.Views.PlaylistsView
  Item = App.Views.PlaylistsItemView

  template: _.template '''
    <div data-role="header"></div>
    <div data-role="content">
      <ul id='playlists-ul'  data-role="listview"/>
    </div>
    '''

  render: ->
    @$el.html @template()
    return unless @programs and @playlists

    $content = @$el.find('div[data-role="content"]')

    $ul = $content.find('ul#playlists-ul')
    $ul.append '<li data-role="list-divider">My Programs</li>'
    
    @programs.each (pl)->
      console.log pl.get('name')
      itemView = new Item
        model: 
          type: 'programs'
          id: pl.id 
          name: pl.get('name')
      $ul.append itemView.render().$el

    $ul.append '<li data-role="list-divider">My Playlists</li>'
    @playlists.each (pl)->
      console.log pl.get('name')
      itemView = new Item
        model: 
          type: 'playlists'
          id: pl.id 
          name: pl.get('name')
      $ul.append itemView.render().$el

    @renderHeader()
    @renderFooter() if @hasFlash

    this


