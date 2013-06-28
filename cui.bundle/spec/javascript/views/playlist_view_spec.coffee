
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
    app = 
      hasTrackPlaying: -> false
    @model = new Playlist({}, app: app) 
    @model.set 'name', 'list 111'
    @view = new PlaylistView
      app: app
      model: @model
      el: $('#playlist')

  it 'should be initialized', ->
    expect(@view).toEqual jasmine.any(PlaylistView)

  describe 'header', ->
    it 'should render refresh icon', ->
      el = @view.render().el
      expect(el).toContain 'div[data-role="header"]'
      expect(el).toContainHtml  '<h1>list 111</h1>'
      expect(el).toContain 'a[data-role="button"][href="#"][data-icon="arrow-l"]'
      expect(el).toContain 'a[data-role="button"][data-icon="refresh"]'
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