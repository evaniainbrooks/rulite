require 'eventmachine'
require 'log4r'

module RuLite
  class PeerConnectionHandler < EM::Connection
    include Bitcoin

    attr_reader :host
    attr_reader :port
    attr_reader :version
    attr_reader :direction

    attr_reader :state
    attr_reader :latency_ms

    def uptime
      (Time.now - @start_time).to_i
    end

    def initialize params
      @context = params[:context]
      @host = params[:host]
      @port = params[:port]
      @direction = params[:direction]
      @log = Log4r::Logger['rulite']

      @protocol_parser = Bitcoin::Protocol::Parser.new(self)
      @lock = Monitor.new
      @start_time = Time.now
    end

    def receive_data data
      @log.debug "Receiving data (#{data.size} bytes)"
      @lock.synchronize { @parser.parse(data) }
    rescue StandardError => e
      @log.error "Error receiving data"
      @log.error e.message
    end
  
    # EM callback
    def post_init
      @log.info "PeerConnectionHandler::post_init" 
    end

    # EM callback
    def connection_completed
      @log.info "PeerConnectionHandler::connection_completed"
    end

    def incoming?
      @direction == :incoming
    end

    def outgoing?
      @direction == :outgoing
    end
  end
end

