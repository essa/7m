

describe 'PlayingTrack', ->
  PlayingTrack = App.Models.PlayingTrack
  describe 'StallDetector', ->
    StallDetector = App.Models.PlayingTrack.StallDetector

    beforeEach ->
      @now = new Date()
      @time = sinon.useFakeTimers(@now.getTime())
      @mockPlaying = new Backbone.Model()
      @mockPlaying.set('status', App.Status.PLAYING)
      @detector = new StallDetector(@mockPlaying)
      @mockPlaying.trigger 'timeupdate', 0

    it 'should be initialized', ->
      expect(@detector).toEqual jasmine.any(StallDetector)

    it 'should watch timeupdate', ->
      @detector.startTimer()
      @mockPlaying.trigger 'timeupdate', 15
      expect(@detector.pos).toEqual 15
      expect(@detector.lastUpdated).toEqual @now

    it 'should fire stallDetected when pos is not changed 5 second', ->
      spy = sinon.spy()
      @mockPlaying.on 'stallDetected', spy
      @mockPlaying.trigger 'timeupdate', 15
      @detector.startTimer()
      @time.tick(5 * 1000)
      expect(spy).toHaveBeenCalled()

    it 'should not fire stallDetected before 5 second', ->
      spy = sinon.spy()
      @mockPlaying.on 'stallDetected', spy
      @mockPlaying.trigger 'timeupdate', 15
      @detector.startTimer()
      @time.tick(4 * 1000)
      expect(spy).not.toHaveBeenCalled()
      @time.tick(1 * 1000)
      expect(spy).toHaveBeenCalled()

    it 'should not fire stallDetected if pos was changed', ->
      spy = sinon.spy()
      @mockPlaying.on 'stallDetected', spy
      @mockPlaying.trigger 'timeupdate', 15
      @time.tick(9 * 1000)
      @mockPlaying.trigger 'timeupdate', 25
      expect(spy).not.toHaveBeenCalled()
      @time.tick(1 * 1000)
      expect(spy).not.toHaveBeenCalled()

    it 'should not fire stallDetected when status is not playing', ->
      @mockPlaying.set('status', App.Status.PAUSED)
      spy = sinon.spy()
      @mockPlaying.on 'stallDetected', spy
      @mockPlaying.trigger 'timeupdate', 15
      @detector.startTimer()
      @time.tick(15 * 1000)
      expect(spy).not.toHaveBeenCalled()


  beforeEach ->
    mockServer.spyAjax()
    @app =
      baseUrl: -> '/'
      options:
        playerDefault: 'PhonegapStreamPlayer'
        players: 
          PhonegapStreamPlayer: 'StreamPlayer(default)'
          PhonegapMediaPlayer: 'MediaPlayer(without background playing)'
    @app.config = new App.Models.Config(@app)
    @playing = new App.Models.PlayingTrack({}, app: @app)
    @playlists = new  App.Models.Playlists([], @app, 'programs')
    @playlist = new App.Models.Playlist({}, app: @app)
    @playlist.parent = @playlists
    spyOn(@playlist, 'fetch').andCallFake (options)->
      options.success()
    @track = new App.Models.Track({}, app: @app)
    spyOn(@track, 'fetch').andCallFake (options)->
      options.success()
    spyOn(@track, 'recordPlayed').andCallFake (options)->
    spyOn(@track, 'recordPaused').andCallFake (options)->
      
    @playing.player = jasmine.createSpyObj 'player', ['playTrack', 'pause', 'startSilent', 'stop']

  it 'should be initialized', ->
    expect(@playing).toEqual jasmine.any(PlayingTrack)

  describe 'Status', ->
    it 'should be INIT on initialize', ->
      expect(@playing.get('status')).toEqual App.Status.INIT

    it 'should be LOADING when track was selected', ->
      runs ->
        @playing.trigger 'playRequest', @playlist, @track
      waitsFor ->
        @playing.get('status') != App.Status.INIT
      runs ->
        expect(@playing.get('status')).toEqual App.Status.LOADING

    it 'should be PALYING when track is playing', ->
      @playing.track = 
        prepareNext: sinon.spy()
      runs ->
        @playing.trigger 'notifyStarted'
      waitsFor ->
        @playing.get('status') != App.Status.INIT
      runs ->
        expect(@playing.get('status')).toEqual App.Status.PLAYING

    it 'should be PAUSED when track was paused', ->
      runs ->
        @playing.trigger 'playRequest', @playlist, @track
        @playing.trigger 'notifyPaused'
      waitsFor ->
        @playing.get('status') == App.Status.PAUSED
      runs ->
        expect(@playing.get('status')).toEqual App.Status.PAUSED

    it 'should be ERROR on error', ->
      runs ->
        @playing.trigger 'error'
      waitsFor ->
        @playing.get('status') != App.Status.INIT
      runs ->
        expect(@playing.get('status')).toEqual App.Status.ERROR


  describe 'playRequest event', ->
    it 'should fire change', ->
      onChange = jasmine.createSpy('change')
      @playing.on 'change', onChange
      @playing.trigger 'playRequest', @playlist, @track
      expect(onChange).toHaveBeenCalled()

    it 'should set the reqeusted playlist', ->
      @playing.trigger 'playRequest', @playlist, @track
      expect(@playing.list).toBe(@playlist)

    it 'should set the reqeusted track', ->
      @playing.trigger 'playRequest', @playlist, @track
      expect(@playing.track).toBe(@track)

    it 'should fetch the current information of track', ->
      @playing.trigger 'playRequest', @playlist, @track
      expect(@track.fetch).toHaveBeenCalled()

    it 'should start player', ->
      playTrack = jasmine.createSpy('playTrack')
      @playing.on 'playTrack', playTrack
      player = @playing.player
      @playing.trigger 'playRequest', @playlist, @track
      expect(playTrack).toHaveBeenCalled()

    describe 'when playing', ->
      beforeEach ->
        @prevTrack = new App.Models.Track({}, app: @app)
        @playing.track = @prevTrack
        @playing.set 'status', App.Status.PLAYING

      it 'should stop player', ->
        player = @playing.player
        @playing.trigger 'playRequest', @playlist, @track
        expect(player.stop).toHaveBeenCalled()
        
  describe 'notifyEnd event', ->
    beforeEach ->
      @playing.track = @track

    it 'should fire playNextOf', ->
      @playing.set('status', App.Status.PLAYING)
      @playing.list = @playlist
      @playing.track = @track
      spy = sinon.spy()
      @playing.on 'playNextOf', spy
      @playing.trigger 'notifyEnd'
      expect(spy).toHaveBeenCalled()

    it 'should record played', ->
      @playing.set 'status', App.Status.PLAYING
      @playing.list = @playlist
      @playing.track = @track
      @playing.trigger 'notifyEnd'
      expect(@track.recordPlayed).toHaveBeenCalled()

    describe 'one track play', ->
      it 'should not fire playNextOf', ->
        @playing.set('status', App.Status.PLAYING)
        @playing.list = null
        @playing.track = @track
        spy = sinon.spy()
        @playing.on 'playNextOf', spy
        @playing.trigger 'notifyEnd'
        expect(spy).not.toHaveBeenCalled()


  describe 'pauseRequest event', ->
    beforeEach ->
      @playing.track = @track

    it 'should pause player', ->
      player = @playing.player
      @playing.trigger 'pauseRequest'
      expect(player.pause).toHaveBeenCalled()

    it 'should record paused', ->
      player = @playing.player
      runs =>
        @playing.trigger 'pauseRequest'
      waitsFor =>
        @track.recordPaused.calls.length > 0
      runs =>
        expect(@track.recordPaused).toHaveBeenCalled()

  describe 'pause_at', ->
    beforeEach ->
      @playing.track = @track
      @playing.set 'pause_at', 60

    it 'should fire skipRequest at pause_at', ->
      spy = sinon.spy() 
      @playing.on 'skipRequest', spy
      @playing.trigger 'timeupdate', 60
      expect(spy).toHaveBeenCalled()

    it 'should not fire skipRequest until pause_at', ->
      spy = sinon.spy() 
      @playing.on 'skipRequest', spy
      @playing.trigger 'timeupdate', 59
      expect(spy).not.toHaveBeenCalled()

    it 'should fire skipRequest once', ->
      spy = sinon.spy() 
      @playing.on 'skipRequest', spy
      @playing.trigger 'timeupdate', 59
      expect(spy).not.toHaveBeenCalled()
      @playing.trigger 'timeupdate', 60
      expect(spy).toHaveBeenCalledOnce()
      @playing.trigger 'timeupdate', 61
      expect(spy).toHaveBeenCalledOnce()


