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
require 'fileutils'

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
      FileUtils::mkdir_p SevenMinutes::Config::application_support_directory
      ITunes::init_itunes(SevenMinutes::base_dir)
      playlists = ITunes::Playlist::all.map do |pl|
        pl.name
      end
      p playlists
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
      logger.open_logfile(conf[:logfile]) 

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
          @max = 500
          @queue = Dispatch::Queue.main
          @logfile = nil
        end

        def open_logfile(logfile)
          @logfile = logfile
        end

        LENGTH_OF_DATETIME = 14

        def write(str)
          @queue.async do
            if @logfile
              File::open(@logfile, 'a') do |f|
                f.puts str
              end
            end

            color = case str
                    when / :I /
                      NSColor::blueColor
                    when / :D /
                      NSColor::blackColor
                    else
                      NSColor::redColor
                    end
            attr_str = NSMutableAttributedString.alloc.initWithString(str+"\n")
            attr_str.addAttribute(NSForegroundColorAttributeName,
                value: NSColor.grayColor,
                range: NSMakeRange(0, LENGTH_OF_DATETIME))
            attr_str.addAttribute(NSForegroundColorAttributeName,
                value: color,
                range: NSMakeRange(LENGTH_OF_DATETIME, attr_str.length-LENGTH_OF_DATETIME))
            @tv.insertText attr_str

            @logs << str
            if @logs.size > @max
              len = @tv.textStorage.string.each_line.first.size
              @tv.textStorage.deleteCharactersInRange NSMakeRange(0, len)
              @logs.shift 
            end
            
            newScrollOrigin=NSMakePoint(0.0,10000.0)
            @tv.scrollPoint(newScrollOrigin)

            # @tv.setString(@logs.join("\n"))
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

      def open_logfile(logfile)
        @dev.open_logfile(logfile)
      end

      def write(msg)
        self.info(msg.chomp)
      end
    end
  end
end

