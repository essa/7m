
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
    @playlists.each (pl)->
      itemView = new Item
        model: 
          type: 'playlists'
          id: pl.id 
          name: pl.get('name')
      $ul2.append itemView.render().$el

    @renderHeader()
    @renderFooter() if @hasFlash

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

