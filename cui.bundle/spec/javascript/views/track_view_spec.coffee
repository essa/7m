
describe 'TrackView', ->
  TrackViewForEmbendedPlayer = App.Views.TrackViewForEmbendedPlayer
  TrackViewForExternalPlayer = App.Views.TrackViewForExternalPlayer
  Playlist = App.Models.Playlist
  Track = App.Models.Track
  beforeEach ->
    $('#stage').html '''
    <div id="playlist">
      <div data-role="header"></div>
      <div data-role="content">
        <div id='popup-div' />
      </div>
    </div>
    '''
    $.fn.rateit = sinon.spy()
    @app = 
      hasTrackPlaying: -> false
      on: sinon.spy()
      trigger: sinon.spy()
      router:
        navigate: sinon.spy()
      config:
        bps: -> 128
      baseUrl: -> 'http://base/'
    @list = new Playlist
      id: 111
    ,
      app: @app 
    @list.set 'name', 'list 111'
    @track = new Track
      id: 123
      name: 'track1 name'
      artist: 'track1 artist'
    ,
      app: @app
      type: 'programs'


  describe 'TrackViewForEmbendedPlayer', ->
    beforeEach ->
      @view = new TrackViewForEmbendedPlayer
        app: @app
        model: @track
        el: $('#playlist')
        type: 'programs'
        playlist: @list

    it 'should be initialized', ->
      expect(@view).toEqual jasmine.any(TrackViewForEmbendedPlayer)

    describe 'header', ->
      it 'should display title', ->
        expect(@view.render().el).toContainHtml '<h1>track1 name</h1>'

      it 'should have back link', ->
        expect(@view.render().el).toContain 'a[href="#programs/111"]'

    describe 'footer', ->
      it 'should have play button', ->
        expect(@view.render().el).toContain 'div[data-role="footer"]'
        footer = @view.render().$el.find('div[data-role="footer"]')
        expect(footer).toContainText 'Play!'

    describe 'play-button', ->
      beforeEach ->
        @view.render()
        $('#button-play').trigger('tap')

      it 'should trigger playRequest on tap', ->
        expect(@app.trigger).toHaveBeenCalled()
        call = @app.trigger.getCall(0)
        expect(call.args).toEqual ['playRequest', @list, @track]

    describe 'play-panel', ->
      beforeEach ->
        $.fn.popup = sinon.spy()
        @view.render()
        $('#button-play').trigger('taphold')

      it 'should have buttons for playing ', ->
        expect(@view.el).toContain 'div[data-role="popup"]'
        expect($.fn.popup).toHaveBeenCalled()
        panel = @view.$el.find('div[data-role="popup"]')
        expect(panel).toContainText 'Play only this track'
        expect(panel).toContainText 'Play this track full duration'

      it 'should play only this track', ->
        $('#button-play-track').trigger('tap')
        expect(@app.trigger).toHaveBeenCalled()
        call = @app.trigger.getCall(0)
        expect(call.args).toEqual ['playRequest', null, @track, {}]

      it 'should play only this track full duration', ->
        $('#button-play-track-full').trigger('tap')
        expect(@app.trigger).toHaveBeenCalled()
        call = @app.trigger.getCall(0)
        expect(call.args).toEqual ['playRequest', null, @track, full: true]


  describe 'TrackViewForExternalPlayer', ->
    beforeEach ->
      @view = new TrackViewForExternalPlayer
        app: @app
        model: @track
        el: $('#playlist')
        type: 'programs'
        playlist: @list

    it 'should be initialized', ->
      expect(@view).toEqual jasmine.any(TrackViewForExternalPlayer)

    describe 'play-button', ->
      beforeEach ->
        $.fn.popup = sinon.spy()
        @view.render()
        $('#button-play').trigger('tap')

      it 'should show popup', ->
        expect(@view.el).toContain 'div[data-role="popup"]'
        expect($.fn.popup).toHaveBeenCalled()
        panel = @view.$el.find('div[data-role="popup"]')
        expect(panel).toContainText 'Play only this track'
        expect(panel).toContainText 'Play this track full duration'

