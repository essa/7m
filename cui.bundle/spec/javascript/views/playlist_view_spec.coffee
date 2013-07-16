
describe 'PlaylistView', ->
  PlaylistView = App.Views.PlaylistViewForEmbendedPlayer
  Playlist = App.Models.Playlist
  beforeEach ->
    $('#stage').html '''
    <div id="playlist">
      <div data-role="header"></div>
      <div data-role="content"></div>
    </div>
    '''
    $.mobile = 
      popup: {}
    app = 
      baseUrl: -> '/'
      hasTrackPlaying: -> false
      trigger: sinon.spy()
    @model = new Playlist({}, app: app) 
    sinon.stub @model, 'refresh', ->
    sinon.stub @model.tracks, 'fetch', ->
    @model.set 'name', 'list 111'
    @view = new PlaylistView
      app: app
      model: @model
      el: $('#playlist')

  afterEach ->
    @model.refresh.restore()

  it 'should be initialized', ->
    expect(@view).toEqual jasmine.any(PlaylistView)

  describe 'header', ->
    it 'should render refresh icon', ->
      el = @view.render().el
      expect(el).toContain 'div[data-role="header"]'
      expect(el).toContainHtml  '<h1>list 111</h1>'
      expect(el).toContain 'a[data-role="button"][href="#"][data-icon="arrow-l"]'
      expect(el).toContain 'a[data-role="button"][data-icon="refresh"]'

  describe 'refresh button', ->
    describe 'when tapped', ->
      beforeEach ->
        @view.render().$el.find('#button-list-refresh').trigger('tap')

      it 'should sync the tracks', ->
        expect(@model.tracks.fetch).toHaveBeenCalled()

  describe 'refresh-panel', ->
    beforeEach ->
      $.fn.popup = sinon.spy()
      @view.render()
      $('#button-list-refresh').trigger('taphold')

    it 'should have buttons for refreshing ', ->
      expect(@view.el).toContain 'div[data-role="popup"]'
      expect($.fn.popup).toHaveBeenCalled()
      panel = @view.$el.find('div[data-role="popup"]')
      expect(panel).toContainText 'Clear and Refresh'
      expect(panel).toContainText 'Refresh and Play'

    it 'should clear and refresh', ->
      $('#button-list-clear-and-refresh').trigger('tap')
      expect(@model.refresh).toHaveBeenCalled()
      
    it 'should refresh and play', ->
      $('#button-list-refresh-and-play').trigger('tap')
      expect(@view.app.trigger).toHaveBeenCalled()

"""
  describe 'contents', ->
    it 'should render programs', ->
      @programs.add new Playlist
        name: 'program a1'
        id: 123
      expect(@view.render().el).toContainText 'program a1' 
      expect(@view.render().el).toContain 'a[href="#programs/123"]' 

    it 'should render playlists', ->
      @playlists.add new Playlist
        name: 'playlist a1'
        id: 123
      @playlists.add new Playlist
        name: 'playlist b2'
        id: 234
      expect(@view.render().el).toContainText 'playlist a1' 
      expect(@view.render().el).toContainText 'playlist b2' 
      expect(@view.render().el).toContain 'a[href="#playlists/123"]' 
      expect(@view.render().el).toContain 'a[href="#playlists/234"]' 
"""
