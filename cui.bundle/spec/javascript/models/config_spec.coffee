console.log 'Config spec'

describe 'Config', ->
    beforeEach ->
      @app = 
        options:
          playerDefault: 'PhonegapStreamPlayer'
          players: 
            PhonegapStreamPlayer: 'StreamPlayer(default)'
            PhonegapMediaPlayer: 'MediaPlayer(without background playing)'
      @config = new App.Models.Config(@app)

    it 'should have default attributes', ->
      @config.resetToDefault()
      attr = @config.attributes
      expect(attr.server_addr).toEqual ''
      expect(attr.server_port).toEqual ''

    # it 'should save attrs to localStorage', ->
      # @config.set 'server_addr', '192.168.1.23'
      # @config.saveToLocalStorage()
      # new_config = new App.Models.Config(@app)
      # expect(new_config.get('server_addr')).toEqual ''
      # new_config.loadFromLocalStorage()
      # expect(new_config.get('server_addr')).toEqual '192.168.1.23'

    # it 'should be detected new or old', ->
      # expect(@config.get('new_config')).toEqual true
      # expect(@config.isNewConfig()).toEqual true
      # @config.saveToLocalStorage()
      # new_config = new App.Models.Config(@app)
      # new_config.loadFromLocalStorage()
      # expect(new_config.get('new_config')).toEqual false
      # expect(@config.isNewConfig()).toEqual false
