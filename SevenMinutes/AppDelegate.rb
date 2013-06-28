#
#  AppDelegate.rb
#  TokyoTower
#
#  Created by Nakajima Taku on 2013/04/25.
#  Copyright 2013年 Nakajima Taku. All rights reserved.
#


$: << NSBundle.mainBundle.resourcePath + '/cui.bundle'
require 'rubygems'
require 'gui'

class AppDelegate
  attr_accessor :window, :logview, :config_path_label, :config_text
  

  def initialize
    p 'AppDelegate::initialize'
    SevenMinutes::Gui::create_default_config
  end

  def applicationDidFinishLaunching(a_notification)
    p 'AppDelegate::applicationDidFinishLaunching'
    @logger = SevenMinutes::Gui::TextViewLogger.new(self.logview)
    @config_path = File::join(SevenMinutes::Config::application_support_directory, "7m.yml")
    config_path_label.setStringValue @config_path
    load_config
    @server = SevenMinutes::Gui::start_as_gui(@logger)
    p 'AppDelegate::applicationDidFinishLaunching end'
  rescue Errno::ENOENT
    p $!
    @logger.fatal "can't find config file #{$!}" 
  end
  
  def start_clicked(sender)
    @logger.info 'starting......'
    @server = SevenMinutes::Gui::start_as_gui(@logger)
    start_webserver
    @logger.info 'started'
  end
  
  def restart_clicked(sender)
    @logger.info 'restarting......'
    stop_webserver
    start_webserver
    @logger.info 'restarted'
  end
  
  def stop_clicked(sender)
    @logger.info 'stoping....'
    stop_webserver
    @logger.info 'stoped'
  end
  
  def config_save_clicked(sender)
    save_config
  end
  
  def config_reload_clicked(sender)
    load_config
  end

  private
  def start_webserver
    @server = SevenMinutes::Gui::start_as_gui(@logger)
  end
  def stop_webserver
    @server.stop
  end
  def load_config
    @logger.info "loading config file from #{@config_path}"
    File::open(@config_path) do |f|
      self.config_text.setString f.read
    end
    @logger.info 'loaded'
  end

  def save_config
    @logger.info 'saving config file'
    File::open(@config_path, 'w') do |f|
      f.write self.config_text.string
    end
    @logger.info 'saved'
  end
end

