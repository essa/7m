
describe 'Track', ->
  Track = App.Models.Track
  beforeEach ->
    @track = new Track {},
      app:
        baseUrl: -> 'http://base/'
    @track.set 'path', 'playlists/123/tracks/456'

  it 'should be initialized', ->
    expect(@track).toEqual jasmine.any Track

  it 'should have url()', ->
    expect(@track.url()).toEqual 'http://base/playlists/123/tracks/456'

  describe 'mediaUrl', ->
    it 'should have mediaUrl()', ->
      expect(@track.mediaUrl()).toEqual 'http://base/playlists/123/tracks/456/media/0'

    it 'should have mediaUrl for bps', ->
      expect(@track.mediaUrl(bps: 128)).toEqual 'http://base/playlists/123/tracks/456/media/128'

    it 'should have mediaUrl for start and stop', ->
      expect(@track.mediaUrl(bps: 128, start:100)).toEqual 'http://base/playlists/123/tracks/456/media/128/100-'
      expect(@track.mediaUrl(bps: 128, start:100, pause: 200)).toEqual 'http://base/playlists/123/tracks/456/media/128/100-200'

  describe 'recordPlayed', ->
    beforeEach ->
      @now = new Date()
      @clock = sinon.useFakeTimers(@now.getTime())
      @ajax = sinon.stub($, 'ajax')

    afterEach ->
      @clock.restore()
      @ajax.restore()

    it 'should send PATCH request to the url', ->
      @track.recordPlayed()
      expect(@ajax).toHaveBeenCalledOnce()
      args = @ajax.getCall(0).args[0]
      expect(args.type).toEqual 'POST'
      expect(args.patch).toEqual true
      expect(args.url).toEqual 'http://base/playlists/123/tracks/456'
      data = JSON.parse(args.data)
      expect(data.bookmark).toEqual 0
      expect(data.playedDate).toEqual @now.toString()
  
  describe 'recordPaused', ->
    beforeEach ->
      @ajax = sinon.stub($, 'ajax')

    afterEach ->
      @ajax.restore()

    it 'should update bookmark', ->
      @track.recordPaused(321)
      expect(@ajax).toHaveBeenCalledOnce()
      args = @ajax.getCall(0).args[0]
      expect(args.type).toEqual 'POST'
      expect(args.patch).toEqual true
      expect(args.url).toEqual 'http://base/playlists/123/tracks/456'
      data = JSON.parse(args.data)
      expect(data.bookmark).toEqual 321
      expect(data.bookmarkable).toEqual true

  describe 'prepareMedia', ->
    beforeEach ->
      @ajax = sinon.stub($, 'ajax')

    afterEach ->
      @ajax.restore()

    it 'should request media creation', ->
      @track.prepareMedia(bps: 128)
      expect(@ajax).toHaveBeenCalledOnce()
      args = @ajax.getCall(0).args[0]
      expect(args.type).toEqual 'HEAD'
      expect(args.patch).toEqual undefined
      expect(args.url).toEqual 'http://base/playlists/123/tracks/456/media/128'

  describe 'mediaPrepared', ->
    beforeEach ->
      @server = sinon.fakeServer.create()

    afterEach ->
      @server.restore()

    it 'should be true on success', ->
      @server.respondWith 'http://base/playlists/123/tracks/456/media/128', [200, {}, 'OK']
      ret = @track.mediaPrepared(bps: 128)
      expect(ret).toEqual true

    it 'should be false on not found', ->
      @server.respondWith [404, {}, 'NOT FOUND']
      ret = @track.mediaPrepared(bps: 128)
      expect(ret).toEqual false
