

class App.Views.ConfigView extends Backbone.View
  seq: 2
  transition: 'slideup'
  events:
    "click #config-save" : "save"
    "click #config-reset" : "reset"
  template: _.template '''
    <div data-role="header">
      <h1 id='config-header'>Config</h1>
    </div>
    <div data-role="content">
      <fieldset data-role="controlgroup" data-type="horizontal">
        <legend>Interface:</legend>
        <input type="radio" name="interface" id="interface-default" checked='checked' value='default'></input>
        <label for="interface-default">Default</label>
        <input type="radio" name="interface" id="interface-pc" value='pc'></input>
        <label for="interface-pc">PC</label>
        <input type="radio" name="interface" id="interface-mobile" value='mobile'></input>
        <label for="interface-mobile">Mobile</label>
      </fieldset>
      <fieldset data-role="controlgroup" data-type="horizontal">
        <legend>Max kbps:</legend>
        <input type="radio" name="bps" id="bps-none" checked='checked' value='none'></input>
        <label for="bps-none">None</label>
        <input type="radio" name="bps" id="bps-32" value='32'></input>
        <label for="bps-32">32</label>
        <input type="radio" name="bps" id="bps-48" value='48'></input>
        <label for="bps-48">48</label>
        <input type="radio" name="bps" id="bps-64" value='64'></input>
        <label for="bps-64">64</label>
        <input type="radio" name="bps" id="bps-96" value='96'></input>
        <label for="bps-96">96</label>
        <input type="radio" name="bps" id="bps-128" value='128'></input>
        <label for="bps-128">128</label>
      </fieldset>
      <% if (isPhonegap) { %>
        <label for="server-addr">Server:</label>
        <input type="text" name="server-addr" id="server-addr" value=""/>
        <label for="server-port">Port:</label>
        <input type="text" name="server-port" id="server-port" value=""/>
      <% } %>
      <hr />
      <a href='#' id='config-save' data-role="button" data-inline='true'>save</a>
      <a href='#' data-role="button" data-inline='true'>cancel</a>
      <a href='#' id='config-reset' data-role="button" data-inline='true'>reset</a>
    </div>
  '''

  initialize: (options)->
    super(options)
    @model.loadFromLocalStorage()

  render_header: ->
    $header = @$el.find('div[data-role="header"]')
    if $header.find('h1').size() == 0
      console.log 'rendering playlists header'
      header_view = new App.Views.HeaderView
        el: $header
        model:
          right_icon: 'gear'
          right_href: 'config'
          title: 'SevenMinutes'
      header_view.render()

  render: ->
    @$el.html @template
      isPhonegap: App.isPhonegap
    @render_header()
    @$el.find('#server-addr').val @model.get('server_addr')
    @$el.find('#server-port').val @model.get('server_port')

    face = @model.get('face')
    $("#interface-#{face}").attr('checked', true).trigger('create')
    
    bps = @model.get('bps')
    $("#bps-#{bps}").attr('checked', true).trigger('create')
    this

  save: ->
    bps = $('input[name="bps"]').filter(':checked').val();
    face = $('input[name="interface"]').filter(':checked').val();
    @model.set
      server_addr: @$el.find('#server-addr').val()
      server_port: @$el.find('#server-port').val()
      bps: bps
      face: face
    ret =  @model.saveToLocalStorage()
    console.log 'saveToLocalStorage returned', ret
    if ret
      console.log 'saveToLocalStorage ok', ret
      App.router.navigate('playlists', trigger: true)
    else
      console.log 'saveToLocalStorage error', ret
      App.router.navigate('config', trigger: true)

  reset: ->
    @model.resetToDefault()
    Env.reset()

  close: ->
    @undelegateEvents()
    @stopListening()
