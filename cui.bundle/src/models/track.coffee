
class App.Models.Track extends Backbone.Model
  initialize: (attrs, options)->
    super(attrs, options)
    @app = options.app

  url: -> 
    path = @get('path')
    "#{@app.baseUrl()}#{path}"

  mediaUrl: (options={})->
    url = if options.bps? and options.bps != undefined
            @url() + "/media/#{options.bps}"
          else
            @url() + '/media/0'
    start = parseInt(options.start)
    pause = parseInt(options.pause)
    if start > 0 and pause > 0
      url += "/#{start}-#{pause}"
    else
      if start > 0
        url += "/#{start}-"
      else
        if pause > 0
          url += "/0-#{pause}"
    url += '?prepareNext=no' if options.prepareNext == 'no'
    url

  toJSON: ->
    json = super()
    json.app = undefined
    json

  recordPlayed: (options={})->
    if options.completed
      @save
        bookmark: 0
        played: 1
        playedDate:  new Date().toString()
        playedCount: @get('playedCount') + 1
      ,
        patch: true
        success: -> console.log "recordPlayed save success"
        error: -> console.log "recordPlayed save error"
    else
      bookmark = @get('pause_at')
      if parseInt(bookmark) > 0
        @recordPaused(bookmark, completed: true)
      else
        @recordPlayed(completed: true)

  recordPaused: (bookmark, options={})->
    console.log JSON.stringify(@attributes),bookmark
    @save
      bookmark: bookmark
      played: if options.completed then 1 else 0
      bookmarkable: true
    ,
      patch: true
      success: -> console.log "recordPaused save success"
      error: -> console.log "recordPaused save error"

  prepareMedia: (options)->
    options.create = true
    options.url = @mediaUrl(options)
    options.type = 'HEAD'
    $.ajax options

  mediaPrepared: (options)->
    options.url = @mediaUrl(options)
    console.log options.url
    options.type = 'HEAD'
    options.async = false
    ret = false
    options.success = -> ret = true
    $.ajax options
    ret

  prepareNext: ->
    bps = App.config?.get('max_bps')
    return unless bps?
    next_media_path = @get('next_media_path')
    return unless next_media_path?
    return if @prepared

    next_media_url = "#{App.baseUrl()}#{next_media_path}?maxBitRate=#{bps}"
    console.log 'prepareNext', next_media_url
    setTimeout ->
      console.log 'prepareNext fire', next_media_url
      $.ajax
        url: next_media_url
        method: 'head'
    , 30*1000
    @prepared = true

