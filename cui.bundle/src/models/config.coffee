
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
    console.log 'config player = ', @defaultPlayer

  KEY: '7m.config'
  defaults:
    server_addr: ''
    server_port: ''
    new_config: true

  player: ->
    if @get('player')?
      @get('player')
    else
      @defaultPlayer
  
  resetToDefault: ->
    window.localStorage.setItem(@KEY, undefined)

  saveToLocalStorage: ->
    console.log 'saveToLocalStorage 0'
    error = @validate(@attributes)
    console.log 'saveToLocalStorage 1', error
    if error
      alert(error)
      return false
    @set('new_config', false)
    @attributes.bps = undefined if @attributes.bps == 'none'
    try
      data = JSON.stringify @attributes
      console.log data
      window.localStorage.setItem(@KEY, data)
      return true
    catch e
      alert(e)
      return false

  loadFromLocalStorage: ->
    console.log 'loadFromLocalStorage '
    data = window.localStorage.getItem(@KEY);
    console.log data
    try 
      @set(JSON.parse(data)) if data?
    catch e 
      console.log 'loadFromLocalStorage error', e

    console.log 'loadFromLocalStorage end'

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
      else
        ((typeof navigator.plugins != "undefined" && typeof navigator.plugins["Shockwave Flash"] == "object") || (window.ActiveXObject && (new ActiveXObject("ShockwaveFlash.ShockwaveFlash")) != false))

  isMobile: ->
    switch @get('face')
      when 'pc'
        false
      when 'mobile'
        true
      else
        /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent) 

  validate: (attrs)->
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
    


