

describe 'Playlists', ->
  beforeEach ->
    @app = 
      baseUrl: -> 'http://some.host.com/'

    @playlists = new App.Models.Playlists [],
      app: @app
      type: 'programs'

  describe 'initializing', ->
    it 'should have app', ->
      expect(@playlists.app).toBe @app
    it 'should have type', ->
      expect(@playlists.type).toEqual 'programs'

  describe '#url', ->
    it 'should return baseUrl/playlists', ->
      expect(@playlists.url()).toEqual 'http://some.host.com/programs' 
 
  describe '#getPlaylist', ->
    describe 'when it was fetched before', ->
      beforeEach ->
        @playlists.add
          id: '2345'
          name: 'abc'
      it 'should return it', ->
        console.log @playlists.at(0)
        expect(@playlists.at(0)).toEqual jasmine.any App.Models.Playlist
        expect(@playlists.at(0).id).toEqual '2345'
        @playlists.getPlaylist '2345', (pl)->
          expect(pl.get('name')).toEqual 'abc'

      it 'should have same app and type', ->
        @playlists.getPlaylist '2345', (pl)=>
          expect(pl.type).toEqual 'programs'
          expect(pl.app).toBe @app


"""
    it 'should return one with the id if already feteched', ->
      pl = null
      runs ->
        @playlists.getPlaylist 2345, (l)->
          pl = l
      waitsFor ->
        pl?
      runs ->
        expect($.ajax.calls.length).toEqual 1
        @playlists.getPlaylist 1234, (l)->
          expect($.ajax.calls.length).toEqual 1 # check ajax has not been called
          expect(l).toEqual jasmine.any(App.Models.Playlist)
          expect(l.get('name')).toEqual 'aaa'
    beforeEach mockServer.spyAjax
    it 'should fetch all playlists and return one with the id', ->
      pl = null
      runs ->
        @playlists.getPlaylist 2345, (l)->
          pl = l
      waitsFor ->
        pl?
      runs ->
        expect(pl).toEqual jasmine.any(App.Models.Playlist)
        expect(@playlists.length).toEqual 2
        expect(@playlists.at(0).get('name')).toEqual 'aaa'
        expect(@playlists.at(1).get('name')).toEqual 'bbb'
        expect(@playlists.get(1234).get('name')).toEqual 'aaa'
        expect(@playlists.get(2345).get('name')).toEqual 'bbb'
        expect(@playlists.get(9999)).not.toBeDefined()



"""
