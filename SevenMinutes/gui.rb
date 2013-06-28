#
#  gui.rb
#  TokyoTower
#
#  Created by Nakajima Taku on 2013/06/03.
#  Copyright 2013年 Nakajima Taku. All rights reserved.
#

require 'control_tower_ext'
require 'yaml'
require 'logger'

require 'version'
require 'config'
require 'itunes'
require 'radio_program'

module SevenMinutes
  def self.base_dir
    NSBundle.mainBundle.resourcePath.fileSystemRepresentation + '/cui.bundle'
  end

  module Gui
    def self.create_default_config
      template_path = File::join(SevenMinutes::base_dir, "7m.yml.sample.erb")
      path = File::join(SevenMinutes::Config::application_support_directory, "7m.yml")
      return if File::exists?(path)
      File::mkdir_p SevenMinutes::Config::application_support_directory
      ITunes::init_itunes(SevenMinutes::base_dir)
      playlists = []
      ITunes::app.sources[0].playlists.map do |pl|
        next if pl.name == 'ムービー'
        next if pl.name == 'ライブラリ'
        next if pl.name == 'テレビ番組'
        next if pl.name == 'ミュージックビデオ'
        next if pl.name == 'Genius'
        playlists << pl.name
      end
      File::open(template_path) do |tmpl|
        require 'erb'
        erb = ERB.new(tmpl.read)
        p playlists
        File::open(path, 'w') do |f|
          f.puts erb.result(binding)
        end
      end
    end

    def self.start_as_gui(logger)
      logger.level = Logger::INFO
      logger.info "SevenMinutes #{SevenMinutes::VERSION} start"

      conf = Config::load(
        config_file: '7m.yml',
        mode: Config::GUI,
        logger: logger
      )

      ITunes::init_app(conf)
      RadioProgram::Program::init(conf, ITunes)
      require 'webapp'

      ENV['RACK_ENV'] = 'production'

      port = conf[:port] || 16017
      bindaddr = conf[:bindaddr] || '0.0.0.0'

      options = {
        :port => port,
        :host => bindaddr,
        :concurrent => true,
        :logger => logger
      }

      logger.info "starting server port=#{port} bind address=#{bindaddr}"
      app = SevenMinutes::App.new(conf)
      app = SevenMinutes::CommonLogger.new(app, logger)
      server = ControlTowerExt::Server.new(app, options)
      Thread.start do
        server.start
      end
      server
    end

    class TextViewLogger < Logger
      class LogDev
        def initialize(tv)
          @tv = tv
          @logs = []
          @max = 50
          @queue = Dispatch::Queue.main
        end

        def write(str)
          @queue.async do
            @logs << str
            @logs.shift if @logs.size > @max
            @tv.setString(@logs.join("\n"))
            #@tv.insertText str
          end
        end

        def close
        end
      end

      def initialize(textview)
        @dev = LogDev.new(textview)
        super(@dev)
        self.formatter = proc do |severity, datetime, progname, message|
          "#{datetime.strftime('%m-%dT%H:%M:%S ')}:#{severity[0]} #{message}"
        end
      end

      def write(msg)
        self.info(msg.chomp)
      end
    end
  end
end

