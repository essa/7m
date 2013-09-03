

describe 'MediaManager', ->
  ClientManagedMM = App.Players.ClientManagedMM
  ServerManagedMM = App.Players.ServerManagedMM
  ListMM = App.Players.ListMM
  beforeEach ->
    @app =
      baseUrl: -> 'http://mock.server/'
    @player = {}
    _.each ['play', 'stop'], (m)=> 
      @player[m] = ->
      sinon.stub(@player, m)
    @playing = new Backbone.Model

    @list = new App.Models.Playlist 
      path: 'playlists/123'
    ,
      app: @app

    @track = new App.Models.Track 
      path: 'playlists/123/track/456'
      bookmark: 10
      pause_at: 30
      posInList: 20
      trimedDuration: 26 
    ,
      app: @app

  it 'shoud be initialized', ->
    @mmc = new ClientManagedMM(@playing, @player)
    expect(@mmc).toEqual jasmine.any(ClientManagedMM)
    @mms = new ServerManagedMM(@playing, @player)
    expect(@mms).toEqual jasmine.any(ServerManagedMM)
    @mml = new ListMM(@playing, @player)
    expect(@mml).toEqual jasmine.any(ListMM)

  describe 'onPlayTrack', ->

    describe 'ClientManagedMM', ->
      beforeEach ->
        @mmc = new ClientManagedMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track

      it 'should play track', ->
        expect(@player.play).toHaveBeenCalled()
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/track/456/media/0.mp3?prepareNext=no'
        expect(@player.play.lastCall.args[1]).toEqual 10

    describe 'ServerManagedMM', ->
      beforeEach ->
        @mms = new ServerManagedMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track

      it 'should play track', ->
        expect(@player.play).toHaveBeenCalled()
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/track/456/media/0/10-30.mp3'
        expect(@player.play.lastCall.args[1]).toEqual 0

    describe 'ListMM', ->
      beforeEach ->
        @mml = new ListMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track

      it 'should play track', ->
        expect(@player.play).toHaveBeenCalled()
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/media'
        expect(@player.play.lastCall.args[1]).toEqual 20

  describe 'onPlayTrack with bps', ->
    beforeEach ->
      @list = new App.Models.Playlist 
        path: 'playlists/123'
      ,
        app: @app

      @track = new App.Models.Track 
        path: 'playlists/123/track/456'
        bookmark: 10
        posInList: 20
      ,
        app: @app

    describe 'ClientManagedMM', ->
      beforeEach ->
        @mmc = new ClientManagedMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track, bps: 128

      it 'should play track', ->
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/track/456/media/128.mp3?prepareNext=no'

    describe 'ServerManagedMM', ->
      beforeEach ->
        @mms = new ServerManagedMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track, bps: 128

      it 'should play track', ->
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/track/456/media/128/10-.mp3'

    describe 'ListMM', ->
      beforeEach ->
        @mml = new ListMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track, bps: 128

      it 'should play track', ->
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/media/128'

  describe 'onPlayTrack full', ->
    beforeEach ->
      @list = new App.Models.Playlist 
        path: 'playlists/123'
      ,
        app: @app

      @track = new App.Models.Track 
        path: 'playlists/123/track/456'
        bookmark: 10
        posInList: 20
      ,
        app: @app

    describe 'ServerManagedMM', ->
      beforeEach ->
        @mms = new ServerManagedMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track, bps: 128, full: true

      it 'should play track', ->
        expect(@player.play.lastCall.args[0]).toEqual 'http://mock.server/playlists/123/track/456/media/128.mp3'

  describe 'onTimeUpdate', ->

    describe 'ClientManagedMM', ->
      beforeEach ->
        @mmc = new ClientManagedMM(@playing, @player)
        @timeupdate = sinon.spy()
        @playing.on 'timeupdate', @timeupdate
        @mmc.onTimeUpdate(0)

      it 'should trigger timeupdate', ->
        expect(@timeupdate).toHaveBeenCalled()
        expect(@timeupdate.lastCall.args[0]).toEqual 0

    describe 'ServerManagedMM', ->
      beforeEach ->
        @mms = new ServerManagedMM(@playing, @player)
        @timeupdate = sinon.spy()
        @playing.on 'timeupdate', @timeupdate
        @playing.trigger 'playTrack', @list, @track, bps: 128
        @mms.onTimeUpdate(0)

      it 'should trigger timeupdate', ->
        expect(@timeupdate).toHaveBeenCalled()
        expect(@timeupdate.lastCall.args[0]).toEqual 10

    describe 'ListMM', ->
      beforeEach ->
        @mml = new ListMM(@playing, @player)
        @playing.trigger 'playTrack', @list, @track, bps: 128

      it 'should trigger timeupdate', ->
        @timeupdate = sinon.spy()
        @playing.on 'timeupdate', @timeupdate
        @mml.onTimeUpdate(21)
        expect(@timeupdate).toHaveBeenCalled()
        expect(@timeupdate.lastCall.args[0]).toEqual 1

      it 'should trigger notifyEnd at end of the track', ->
        @notifyEnd = sinon.spy()
        @playing.on 'notifyEnd', @notifyEnd
        @mml.onTimeUpdate(45)
        expect(@notifyEnd).not.toHaveBeenCalled()
        @mml.onTimeUpdate(46)
        expect(@notifyEnd).toHaveBeenCalled()

  describe 'onEnded', ->

    describe 'ClientManagedMM', ->
      beforeEach ->
        @mmc = new ClientManagedMM(@playing, @player)
        @notifyEnd = sinon.spy()
        @playing.on 'notifyEnd', @notifyEnd
        @mmc.onEnded()

      it 'should trigger notifyEnd', ->
        expect(@notifyEnd).toHaveBeenCalled()

