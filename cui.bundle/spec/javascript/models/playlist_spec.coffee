

describe 'Playlist', ->
  Playlist = App.Models.Playlist
  Tracks = App.Models.Tracks
  beforeEach ->
    @playlist = new Playlist {},
      app:
        baseUrl: -> 'http://base/'
    @playlist.set 'path', 'playlists/123'

  it 'should be initialized', ->
    expect(@playlist).toEqual jasmine.any Playlist
    expect(@playlist.tracks).toEqual jasmine.any Tracks

  it 'should have url()', ->
    expect(@playlist.url()).toEqual 'http://base/playlists/123'

  describe 'mediaUrl', ->
    it 'should have mediaUrl()', ->
      expect(@playlist.mediaUrl()).toEqual 'http://base/playlists/123/media'

    it 'should have mediaUrl for bps', ->
      expect(@playlist.mediaUrl(bps: 128)).toEqual 'http://base/playlists/123/media/128'

  describe 'refresh', ->
    beforeEach ->
      @ajax = sinon.stub($, 'ajax')

    afterEach ->
      @ajax.restore()

    it 'should post refresh url', ->
      @playlist.refresh()
      expect(@ajax).toHaveBeenCalled()

      args = @ajax.getCall(0).args[0]
      expect(args.type).toEqual 'POST'
      expect(args.url).toEqual 'http://base/playlists/123/refresh'

  describe 'recordPlayed', ->
    beforeEach ->
      _.each [111, 222, 333], (id)=>
        console.log id
        @playlist.tracks.add
          id: id
          path: "playlists/123/tracks/#{id}"
        ,
          app:
            baseUrl: -> 'http://base/'
      @ajax = sinon.stub($, 'ajax')

    afterEach ->
      @ajax.restore()
    
    it 'should record all tracks played', ->
      @playlist.recordPlayed()
      expect(@ajax).toHaveBeenCalled()
      expect(@ajax.callCount).toEqual @playlist.tracks.length
      expect(_.map @ajax.args, (a)->a[0].url).toEqual [ 
        'http://base/playlists/123/tracks/111',
        'http://base/playlists/123/tracks/222',
        'http://base/playlists/123/tracks/333' 
      ]
      
  describe 'recordPlayed2', ->
    beforeEach ->
      _.each [111, 222, 333], (id)=>
        console.log id
        @playlist.tracks.add
          id: id
          path: "playlists/123/tracks/#{id}"
        ,
          app:
            baseUrl: -> 'http://base/'
      @server = sinon.fakeServer.create()

    afterEach ->
      @server.restore()
    
    it 'should be success when all tracks are success', ->
      @server.respondWith (req)-> req.respond 200, {}, '{}'
      spy = sinon.spy()
      @playlist.recordPlayed(success: spy)
      @server.respond()
      expect(spy).toHaveBeenCalled()

    it 'should be error when some tracks are error', ->
      @server.respondWith 'http://base/playlists/123/tracks/111', [200, {}, '{}']
      @server.respondWith 'http://base/playlists/123/tracks/222', [500, {}, '{}']
      @server.respondWith 'http://base/playlists/123/tracks/333', [200, {}, '{}']
      success = sinon.spy()
      error = sinon.spy()
      @playlist.recordPlayed(success: success, error: error)
      @server.respond()
      expect(success).not.toHaveBeenCalled()
      expect(error).toHaveBeenCalled()

