
require 'rubygems'
require 'control_tower_ext'
require 'yaml'

require 'version'
require 'config'
require 'itunes'
require 'radio_program'

module SevenMinutes
  def self.base_dir
    File::dirname(__FILE__) 
  end

  def self.start_as_cui
    config_file = ARGV.shift || '7m.yml'
    logger = Logger.new(STDOUT)
    logger.formatter = proc do |severity, datetime, progname, message|
      "#{datetime.strftime('%m-%dT%H:%M:%S ')}:#{severity[0]} #{message}\n"
    end
    def logger.write(msg)
      logger.logdevice.write(msg)
    end
    logger.level = Logger::INFO
    logger.info "7mServer #{SevenMinutes::VERSION} cui mode start"

    conf = Config::load(
      config_file: config_file,
      mode: Config::CUI,
      logger: logger
    )
    conf.detect_sox
    ITunes::init_app(conf)
    RadioProgram::Program::init(conf, ITunes)

    require 'webapp'

    ENV['RACK_ENV'] = conf[:env] || 'production'
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
    server.start
  end
end

SevenMinutes::start_as_cui

