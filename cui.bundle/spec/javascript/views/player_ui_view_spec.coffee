
describe 'PlayerUIView', ->
  PlayerUIView = App.Views.PlayerUIView
  PlayingTrack = App.Models.PlayingTrack
  beforeEach ->
    $('#stage').html '''
    <div id="player">
      <div data-role="header"></div>
      <div data-role="content"></div>
    </div>
    '''
    @model = new PlayingTrack {},
      app: {} 
    @view = new PlayerUIView
      app: {} 
      el: $('#player')
      model: @model

  it 'should be initialized', ->
    expect(@view).toEqual jasmine.any(PlayerUIView)

  describe 'header', ->
    # it 'should render back link', ->
      # track = new App.Models.Track {}, {}
      # track.set 'path', 'playlists/123'
      # @model.setTrack track
      # view = new PlayerUIView
        # el: $('#player')
        # model: @model
        # type: 'playlist'
      # el = view.render().el
      # expect(el).toContain 'div[data-role="header"]'
      # expect(el).toContain 'a[href="#playlists/123"]'

  describe 'render()', ->
    it 'should render name', ->
      @model.set 'name', 'a song name'
      expect(@view.render().el).toContainText 'a song name'

    it 'should render album and artist', ->
      @model.set 'artist', 'Weather Report'
      @model.set 'album', 'Mr. Gone.'
      expect(@view.render().el).toContainText 'Weather Report'
      expect(@view.render().el).toContainText 'Mr. Gone'
      
    describe 'bookmark and pause_at', ->
      it 'should render bookmark and pause_at', ->
        @model.set 'bookmark', 61
        @model.set 'pause_at', 122
        expect(@view.render().el).toContainText '00:01:01->00:02:02'

