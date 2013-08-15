

class App.Views.ConfigView extends Backbone.View
  seq: 2
  transition: 'slideup'
  events:
    "click #config-save" : "save"
    "click #config-reset" : "reset"
    "change #dev-only": "change_dev_only"
  template: _.template '''
    <div data-role="header">
      <h1 id='config-header'>Config</h1>
    </div>
    <div data-role="content">
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
        <label for="dev-only">Show developer only options:</label>
        <select name="dev-only" id="dev-only" data-role="slider">
          <option value="off">Off</option>
          <option value="on">On</option>
        </select>
        <div id='dev-only-area'>
          <fieldset data-role="controlgroup" data-type="horizontal">
            <legend>Interface:</legend>
            <input type="radio" name="interface" id="interface-default" checked='checked' value='default'></input>
            <label for="interface-default">Default</label>
            <input type="radio" name="interface" id="interface-pc" value='pc'></input>
            <label for="interface-pc">PC</label>
            <input type="radio" name="interface" id="interface-mobile" value='mobile'></input>
            <label for="interface-mobile">Mobile</label>
            <input type="radio" name="interface" id="interface-mobileold" value='mobileold'></input>
            <label for="interface-mobileold">Mobile(older version)</label>
          </fieldset>
          <label for="use-dummy-player">use dummy player:</label>
          <select name="use-dummy-player" id="use-dummy-player" data-role="slider">
            <option value="off">Off</option>
            <option value="on">On</option>
          </select>
          <div class='ui-grid-b'>
            <div class='ui-block-a'>Version(server): </div>
            <div class='ui-block-b'><%= serverVersion %></div>
          </div>
          <div class='ui-grid-b'>
            <div class='ui-block-a'>Version(client): </div>
            <div class='ui-block-b'><%= clientVersion %></div>
          </div>
          <div class='ui-grid-b'>
            <div class='ui-block-a'>UserAgent: </div>
            <div class='ui-block-b'><%= navigator.userAgent %></div>
          </div>
        </div>
      <hr />
      <a href='#' id='config-save' data-role="button" data-inline='true'>save</a>
      <a href='#' data-role="button" data-inline='true'>cancel</a>
      <a href='#' id='config-reset' data-role="button" data-inline='true'>reset</a>
    </div>
  '''

  initialize: (options)->
    super(options)

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
      serverVersion: @model.status?.version
      clientVersion: App.VERSION
    @render_header()
    @$el.find('#server-addr').val @model.get('server_addr')
    @$el.find('#server-port').val @model.get('server_port')

    face = @model.get('face')
    $("#interface-#{face}").attr('checked', true).trigger('create')
    
    bps = @model.get('bps')
    $("#bps-#{bps}").attr('checked', true).trigger('create')

    dev_only = @model.get('dev_only')
    $('select[name="dev-only"]').val(dev_only).slider().slider('refresh')
    @change_dev_only()

    use_dummy_player = @model.get('use_dummy_player')
    console.log use_dummy_player
    $('select[name="use-dummy-player"]').val(use_dummy_player).slider().slider('refresh')
    this

  change_dev_only: ->
    f = $('select[name="dev-only"]').val()
    console.log 'change_dev_only', f
    if f == "on"
      $('#dev-only-area').show()
    else
      $('#dev-only-area').hide()


  save: ->
    bps = $('input[name="bps"]').filter(':checked').val();
    face = $('input[name="interface"]').filter(':checked').val();
    dev_only = $('select[name="dev-only"]').val()
    use_dummy_player = $('select[name="use-dummy-player"]').val()
    @model.save
      server_addr: @$el.find('#server-addr').val()
      server_port: @$el.find('#server-port').val()
      bps: bps
      face: face
      dev_only: dev_only
      use_dummy_player: use_dummy_player 

    if use_dummy_player == 'on'
      Env.reset()
    else
      App.router.navigate('', trigger: true)

  reset: ->
    @model.resetToDefault()
    Env.reset()

  close: ->
    @undelegateEvents()
    @stopListening()
