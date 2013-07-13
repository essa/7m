
describe 'PlaylistsView', ->
  PlaylistsView = App.Views.PlaylistsView
  Playlist = App.Models.Playlist
  beforeEach ->
    $('#stage').html '''
    <div id="playlists">
      <div data-role="header"></div>
      <div data-role="content"></div>
    </div>
    '''
    app = 
      hasTrackPlaying: -> false
    @programs = new Backbone.Collection()
    @playlists = new Backbone.Collection()
    @view = new PlaylistsView
      app: app
      programs: @programs
      playlists: @playlists
      el: $('#playlists')

  it 'should be initialized', ->
    expect(@view).toEqual jasmine.any(PlaylistsView)

  describe 'header', ->
    it 'should render config icon', ->
      expect(@view.render().el).toContainHtml '''
        <a href='#config' data-role="button" data-icon="gear"  data-iconpos="notext" class="ui-btn-right"></a>
      '''
  describe 'contents', ->
    it 'should render programs', ->
      @programs.add 
        name: 'program a1'
        id: 123
      expect(@view.render().el).toContainText 'program a1' 
      expect(@view.render().el).toContain 'a[href="#programs/123"]' 

    it 'should render playlists', ->
      @playlists.add 
        name: 'playlist a1'
        id: 123
      @playlists.add 
        name: 'playlist b2'
        id: 234
      expect(@view.render().el).toContainText 'playlist a1' 
      expect(@view.render().el).toContainText 'playlist b2' 
      expect(@view.render().el).toContain 'a[href="#playlists/123"]' 
      expect(@view.render().el).toContain 'a[href="#playlists/234"]' 

