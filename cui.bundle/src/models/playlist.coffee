
class App.Models.Playlist extends Backbone.Model
  initialize: (attrs, options)->
    # console.log 'Playlist#initialize', attrs, options
    super(attrs, options)
    @app = options.app 
    @type = options.type
    options.playlist = this
    @tracks = new App.Models.Tracks([], options)
    @tracks.on 'sync', =>
      @trigger('sync')

  url: -> "#{@app.baseUrl()}#{@get('path')}"

  mediaUrl: (options={})->
    url = if options.bps?
            @url() + "/media/#{options.bps}"
          else
            @url() + '/media'
    
    url += '/export' if options.export
    url += '/create' if options.create
    url

  mediaPrepared: (options={})->
    options.url = @mediaUrl(options)
    console.log options.url
    options.type = 'HEAD'
    options.async = false
    ret = false
    options.success = -> ret = true
    $.ajax options
    ret

  refresh: (options={})->
    success = options.success
    error = options.error
    async = options.async
    data = if options.clear
      "?clear=1"
    else
      ""

    console.log "refresh #{data}"
    $.ajax 
      url: @url() + '/refresh' + data
      type: 'POST'
      async: async
      success: =>
        @tracks.fetch
          success: success
          error: error
          async: async
          reset: true
          
  nextUnplayed: (start=null)->
    if @get('queue')
      @tracks.fetch(acync: false)

    i = @tracks.indexOf(start) + 1

    while @tracks.length > i and @tracks.at(i).get('played')
      i++
    @tracks.at(i)

  prepareMedia: (options={})->
    options.type = 'POST'
    options.url = @mediaUrl(options)
    options.error = ->
      alert('error')
    $.ajax options

  recordPlayed: (options={})->
    promisses = @tracks.map (t)->
      t.recordPlayed()
    $.when.apply(null, promisses)
    .done ->
      options.success?()
    .fail ->
      options.error?() 


    
  getTrack: (track_id)->
    ret = null
    tracks = @tracks
    if tracks.length > 0
      ret = tracks.get(track_id)
    else
      tracks.fetch
        async: false
        success: ->
          ret = tracks.get(track_id)
    ret

class App.Models.Tracks extends Backbone.Collection
  initialize: (models, options)->
    @playlist = options.playlist
    @app = options.app
    @type = options.type
    super(models, options)

  url: ->
    "#{@playlist.url()}/tracks"

  model: (attrs, options)->
    # console.log 'Track#model', attrs, options
    options.app = options.collection.app
    options.type = options.collection.type
    new App.Models.Track(attrs, options)

  setPlaylist: (playlist)->
    @playlist = playlist
    @each (t)=>
      t.setPlaylist(playlist)

class App.Models.Query extends Backbone.Model
  initialize: (attrs, options)->
    console.log 'Query#initialize', options
    super(attrs, options)
    @app = options.app 
    @type = 'query'
    options.playlist = this
    @tracks = new App.Models.Tracks([], options)
    @tracks.on 'sync', =>
      @trigger('sync')

  url: -> "#{@app.baseUrl()}search/#{@get('word')}"
