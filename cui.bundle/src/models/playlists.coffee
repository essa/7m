
class App.Models.Playlists extends Backbone.Collection
  initialize: (models, options)->
    # console.log 'Playlists#initialize', models, options
    @app = options.app
    @type = options.type

  model: (attrs, options)->
    # console.log 'Playlists#model', attrs, options
    options.app = options.collection.app
    options.type = options.collection.type
    new App.Models.Playlist(attrs, options)

  url: -> 
    console.log @app
    @app.baseUrl() + @type

  getPlaylist: (id, callback)->
    pl = @get(id)
    if pl
      pl.app = @app
      pl.type = @type
      pl.parent = @
      callback(pl)
    else
      @fetch
        success: ()=>
          pl = @get(id)
          pl.app = @app
          pl.parent = @
          callback(pl)
