
framework 'foundation'
require 'hashie'
require 'utils'

module SevenMinutes
  class Config 
    CUI = 0
    GUI = 1

    def self.application_support_directory
      as = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true).first
      File::join(as, 'SevenMinutes')
    end

    def self.cui_bundle_directory
      NSBundle.mainBundle.resourcePath.fileSystemRepresentation + '/cui.bundle'
    end

    def self.load(options)
      filename = options[:config_file] || '7m.yml'
      mode = options[:mode]
      base_dir = self.base_dir(mode)
      path = self.config_path(mode, filename)
      logger = options[:logger]
      logger.info "loading config from #{path}"
      conf = YAML::load(File::open(path).read).symbolize_keys_recursive
      self.new(conf, options.merge(base_dir: base_dir, config_file: filename, config_path: path, mode: options[:mode]))
    end

    def self.base_dir(mode)
      case mode
      when CUI
        File::dirname(__FILE__) 
      when GUI
        self.cui_bundle_directory
      else
        raise "invalid mode #{mode}"
      end
    end

    def self.config_path(mode, filename)
      case mode
      when CUI
        File::join(self.base_dir(mode), filename)
      when GUI
        File::join(self.application_support_directory, filename)
      else
        raise "invalid mode #{mode}"
      end
    end

    CONF_KEY = :seven_minutes_conf
    def self.with_config(new_attr={})
      oldconf = self.current
      newconf = (oldconf || {}).merge(new_attr)
      newconf[:logger] ||= Logger.new(STDOUT)
      newconf[:shell] ||= Utils::Shell.new(newconf[:logger])
      Thread::current[CONF_KEY] = Config.new(newconf)
      yield
    ensure
      Thread::current[CONF_KEY] = oldconf
    end

    def self.current
      Thread::current[CONF_KEY] || Config.new({})
    end

    attr_reader :conf
    def initialize(conf, options={})
      case conf
      when Hash
        @conf =  options.merge(conf)
      when Config
        @conf =  options.merge(conf.conf)
      else
        raise "can't convert #{conf.class} to Config"
      end
      set_log_level_from_config
    end

    def [](key)
      @conf[key]
    end

    def []=(key, val)
      @conf[key] = val
    end

    def shell
      self[:shell]
    end

    def logger
      self[:logger]
    end

    def merge(hash)
      case hash
      when Hash
        Config.new @conf.merge(hash)
      when Config
        Config.new @conf.merge(hash.conf)
      end
    end

    private

    def set_log_level_from_config
      loglevel = self[:loglevel]
      return unless loglevel
      logger = self[:logger]
      logger.info "setting loglevel to #{loglevel}"
      case loglevel
      when "DEBUG"
        logger.level = Logger::DEBUG
      when "INFO"
        logger.level = Logger::INFO
      when "WARN"
        logger.level = Logger::WARN
      when "ERROR"
        logger.level = Logger::ERROR
      when "FATAL"
        logger.level = Logger::FATAL
      else
        logger.level = Logger::INFO
      end
    end
  end
end
