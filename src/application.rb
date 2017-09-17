require 'yaml'
require 'log4r'
require 'active_support/all'

require_relative 'node'

module RuLite
  class Application
    def initialize
      Log4r::Logger.root.level = Log4r::DEBUG

      @config = YAML.load_file("config/environments/#{ENV['ENV']}.yml").deep_symbolize_keys
      @log = Log4r::Logger.new('rulite', Log4r::DEBUG)
      @log.trace = true

      Log4r::StdoutOutputter.new('console', level: Log4r::WARN)
      Log4r::FileOutputter.new('logfile', filename: @config[:log_path], trunc: false)
    
      @log.add 'console', 'logfile'
    end

    def run!
      @log.info "Starting in #{env} environment"

      node = RuLite::Node.new @config
      node.start
    end

    def env
      ENV['ENV']
    end

    def production?
      env.to_sym.eql? :production
    end

    def development?
      env.to_sym.eql? :development 
    end

    def test?
      env.to_sym.eql? :test 
    end
  end
end

if __FILE__ == $0
  app = RuLite::Application.new
  app.run!
end
