
class App.Models.Config extends Backbone.Model
  constructor: (@app)->
    super()
    @defaultPlayer = if @hasFlash() 
      'JPlayerPlayer' 
    else 
      if @app?.isPhonegap
        'PhonegapStreamPlayer'
      else
        null

  defaults:
    server_addr: ''
    server_port: ''
    new_config: true

  player: ->
    console.log 'config player', @get('use_dummy_player')
    if @get('use_dummy_player') == 'on'
      console.log 'Dummy'
      'DummyPlayer'
    else
      console.log 'not Dummy'
      if @get('player')?
        @get('player')
      else
        @defaultPlayer
  
  resetToDefault: ->
    window.localStorage.setItem(KEY, undefined)

  KEY = '7m.config'
  sync: (method, model, options)->
    switch method
      when 'create'
        try
          model.set 'new_config', false
          data = JSON.stringify model.attributes
          console.log data
          window.localStorage.setItem(KEY, data)
        catch e
          alert(e)
      when 'read'
        data = window.localStorage.getItem(KEY);
        console.log data
        try 
          model.set(JSON.parse(data)) if data?
        catch e 
          console.log 'fetch error', e
      else 
        console.log "can't happen!!! unknown method #{method}"

  isNewConfig: ->
    @get('new_config')

  bps: ->
    bps = @get('bps')
    if bps == 'none'
      undefined 
    else
      bps

  hasFlash: -> 
    switch @get('face')
      when 'pc'
        true
      when 'mobile'
        false
      when 'mobileold'
        false
      else
        ((typeof navigator.plugins != "undefined" && typeof navigator.plugins["Shockwave Flash"] == "object") || (window.ActiveXObject && (new ActiveXObject("ShockwaveFlash.ShockwaveFlash")) != false))

  isMobile: ->
    switch @get('face')
      when 'pc'
        false
      when 'mobile'
        true
      when 'mobileold'
        true
      else
        /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent) 

  validate__: (attrs)->
    ret = null
    try
      console.log 'config validate', attrs, App.isPhonegap
      if App.isPhonegap
        addr = attrs.server_addr
        port = attrs.server_port
        console.log 'config validate', addr, port
        url = if port? and port != ''
          "http://#{addr}:#{port}/"
        else
          "http://#{addr}/"
        $.ajax
          url: url
          type: 'GET'
          async: false
          error: ->
            console.log 'host check error', url
            ret = "can't connect to server #{url}"
            console.log 'host check error', ret
        console.log 'host check end 1', ret
      console.log 'host check end 2', ret
    catch e
      console.log 'validation exception', e
      ret = e.message
    ret
    


