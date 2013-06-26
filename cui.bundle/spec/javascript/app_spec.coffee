          
console.log 'app_spec'
jasmine.DEFAULT_TIMEOUT_INTERVAL = 1000
# 2013-05-22T08:54:12.059
DateRegex = /\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d.\d\d\d/

mockServer =
  app:
    baseUrl: -> 'http://mockServer/'

  playlistsData: [
    {
      id: 1234
      name: "aaa"
    }, {
      id: 2345
      name: "bbb"
    },
  ]

  tracksData: [
    {
      id: 123
      name: "xxx"
      playlist_id: '2345'
    }, {
      id: 456
      name: "yyy"
      playlist_id: '2345'
    }, {
      id: 789
      name: "zzz"
      playlist_id: '2345'
    },
  ]

  spyAjax: ->
    spyOn($, "ajax").andCallFake (params)->
      switch(params.url)
        when mockServer.app.baseUrl() + 'playlists'
          params.success(mockServer.playlistsData) if params?.success
        when mockServer.app.baseUrl() + 'programs'
          params.success(mockServer.playlistsData) if params?.success
        when mockServer.app.baseUrl() + 'playlists/1234'
          params.success(mockServer.playlistsData[0]) if params?.success
        when mockServer.app.baseUrl() + 'programs/1234'
          params.success(mockServer.playlistsData[0]) if params?.success
        when mockServer.app.baseUrl() + 'playlists/2345'
          params.success(mockServer.playlistsData[1]) if params?.success
        when mockServer.app.baseUrl() + 'programs/2345'
          params.success(mockServer.playlistsData[1]) if params?.success
        when mockServer.app.baseUrl() + 'playlists/1234/tracks'
          params.success(mockServer.tracksData)
        when mockServer.app.baseUrl() + 'programs/1234/tracks'
          params.success(mockServer.tracksData)
        when mockServer.app.baseUrl() + 'playlists/2345/tracks'
          params.success(mockServer.tracksData)
        when mockServer.app.baseUrl() + 'programs/2345/tracks'
          params.success(mockServer.tracksData)
        when mockServer.app.baseUrl() + 'playlists/1234/tracks/123'
          params.success(mockServer.tracksData[0]) if params?.success
        when mockServer.app.baseUrl() + 'programs/1234/tracks/123'
          params.success(mockServer.tracksData[0]) if params?.success
        else
          console.log "can't happen!!! ajax to ", params.url

# describe 'initForPhonegap', ->
  # beforeEach ->
    # # @changePage = spyOn($.mobile, 'changePage').andCallFake (page)->
      # # console.log 'changePage stub 1', page

  # afterEach ->
    # Backbone.history.stop()
    # $('#stage').html ''

  # it 'should bind deviceready', ->
      # runs ->
        # spyOn App, 'init'
        # App.initForPhonegap()
        # helper.trigger window.document, 'deviceready'

      # waitsFor ->
        # App.init.calls.length > 0
      # , 'init should be called once', 500

      # runs ->
        # expect(App.init).toHaveBeenCalled()

"""
describe 'App and router', -> 
  beforeEach ->
    console.log 'beforeEach'
    $('#stage').html '''
      <div id='home' data-role="page" />
      <div id='playlists' data-role="page" />
      <div id='playlist' data-role="page" />
    '''
    @fakeAjax = ->
    @ajax = spyOn($, "ajax").andCallFake (params)=>@fakeAjax(params)
    @changeView = spyOn(App, 'changeView').andCallFake (newView)->
      console.log 'changeView stub', newView
      spyOn(newView, 'render').andCallFake ->

    console.log 'beforeEach 2'
    @fireNavigate = (page, ajaxCallCnt, callback)=>
      console.log 'fireNavigate'
      @fakeAjax = (params)->
        console.log 'fake ajax'
        switch(params.url)
          when '/programs'
            params.success(mockServer.playlistsData)
          when '/playlists'
            params.success(mockServer.playlistsData)
          when '/programs/1234'
            params.success(mockServer.playlistsData[0])
          when '/programs/1234/tracks'
            params.success(mockServer.tracksData)
          when '/playlists/1234'
            params.success(mockServer.playlistsData[0])
          when '/playlists/1234/tracks'
            params.success(mockServer.tracksData)
          else
            console.log "can't happen", params

      @ajax.reset()
      runs =>
        console.log "navigate", page
        App.router.navigate page,
          trigger: true
      waitsFor =>
        @ajax.calls.length >= ajaxCallCnt
      , 'waiting', 2000
      runs ->
        callback()

    console.log 'calling App.init()'
    location.hash = ''
    App.player = undefined
    config = new App.Models.Config()
    config.resetToDefault()
    config.set 'player', 'JPlayerPlayer' 
    config.saveToLocalStorage()

    App.init()
    console.log 'called App.init()'

  afterEach ->
    Backbone.history.stop()
    $('#stage').html ''
    location.hash = ''

  describe 'init', ->
    it 'should initialize router', ->
      expect(App.router).toEqual jasmine.any(Backbone.Router)
    it 'should initialize playlists', ->
      expect(App.programs).toEqual jasmine.any(App.Models.Playlists)
      expect(App.playlists).toEqual jasmine.any(App.Models.Playlists)
      expect(App.programs.app).toBe App 
      expect(App.playlists.app).toBe App 

    it 'should initialize playingTrack', ->
      expect(App.playing).toEqual jasmine.any(App.Models.PlayingTrack)
      expect(App.playing.app).toBe App 

    it 'should initialize MediaManager', ->
      expect(App.mediaManager).toEqual jasmine.any(App.Players.MediaManager)


  describe 'baseUrl', ->
    it 'should return / for web', ->
      expect(App.baseUrl()).toEqual '/'

    it 'should return http:... for iphonegap', ->
      App.config.set 'server_addr', 'localhost'
      expect(App.baseUrl()).toEqual 'http://localhost/'

    it 'should return url with port when specified', ->
      App.config.set 'server_addr', 'localhost'
      App.config.set 'server_port', '2345'
      expect(App.baseUrl()).toEqual 'http://localhost:2345/'

  describe 'home', ->
    it 'should fetch playlists', ->
      expect(@ajax).toHaveBeenCalled()
      urls = @ajax.calls.map (call)->call.args[0].url
      expect(urls).toContain("/programs")
      expect(urls).toContain("/playlists")

    it 'should render Views.Playlists', ->
      expect(@changeView).toHaveBeenCalled()
      expect(@changeView.mostRecentCall.args[0]).toEqual jasmine.any(App.Views.PlaylistsView)

  describe '#programs/:id', ->
    it 'should fetch programs/:id', ->
      @fireNavigate 'programs/1234', 3, =>
        urls = @ajax.calls.map (call)->call.args[0].url
        console.log urls, App.Views.PlaylistView.prototype
        expect(urls).toContain("/programs")
        expect(urls).toContain("/programs/1234")
        expect(urls).toContain("/programs/1234/tracks")


"""

