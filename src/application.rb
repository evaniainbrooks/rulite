
module RuLite
  class Application
		def initialize
      @config = YAML.load_file("config/environments/#{ENV['ENV']}.yml")
      @log = Log4r::Logger.new('rulite-node')
      Log4r::FileOutputter.new('rulite-node', filename: @config[:log_path], trunc: false)
    end

    def run!
      @log.info "Starting in #{env} environment"

      node = RuLite::Node.new @config, @log
      node.start
    end

    def env
      ENV['env']
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
