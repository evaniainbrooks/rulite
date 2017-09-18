require 'eventmachine'
require 'log4r'

require_relative 'peer_events_handler'

module RuLite
  class PeerConnectionHandler < EM::Connection

    attr_reader :context
    attr_reader :host
    attr_reader :port
    attr_reader :version
    attr_reader :direction

    attr_accessor :latency

    def uptime
      (Time.now - @start_time).to_i
    end

    def initialize params
      @context = params[:context]
      @host = params[:host]
      @port = params[:port]
      @direction = params[:direction]
      @log = Log4r::Logger['rulite']
      @peer_events_handler = PeerEventsHandler.new(self) 
      @start_time = Time.now
      @latency = @context.config[:connection_timeout]
      
      Bitcoin.network = @context.config[:network]
    end

    def receive_data data
      @log.debug "Receiving data (#{data.size} bytes)"
      @peer_events_handler.on_receive_data data
    rescue StandardError => e
      @log.error "Error receiving data"
      @log.error e.message
    end

    def connection_completed
      @peer_events_handler.on_connected
      add_timeout_handler
    end
  
    def post_init
      if incoming?
        @peer_events_handler.on_connected
        add_timeout_handler
      end
    end

    def unbind
      @peer_events_handler.on_unbind
    end

    def send_version
      version = Bitcoin.network[:protocol_version]
      user_agent = "/rulite:#{Bitcoin::VERSION}/"
      from = "#{@context.external_ip}:#{@context.external_port}"
      version = Bitcoin::Protocol::Version.new({
        version: version,
        last_block: 0,
        from: from,
        to: @host,
        user_agent: user_agent
      })

      @log.debug "Sending version #{version.inspect}"
      send_data(version.to_pkt)
    rescue StandardError => e
      @log.error "Failed to send_version"
      @log.error e.message
    end

    def send_ping
      @ping_nonce = rand(0xffffffff)
      @ping_time = Time.now

      @log.debug "Sending ping #{@ping_nonce}"
      send_data(Bitcoin::Protocol.ping_pkt(@ping_nonce))
    rescue StandardError => e
      @log.error "Failed to send_ping"
      @log.error e.message
    end

    def send_pong nonce
      @log.debug "Sending pong #{nonce}"
      send_data(Bitcoin::Protocol.pong_pkt(nonce)) if nonce
    rescue StandardError => e
      @log.error "Failed to send_pong"
      @log.error e.message
    end

    def incoming?
      @direction == :incoming
    end

    def outgoing?
      @direction == :outgoing
    end

    def add_timeout_handler
      timeout = @context.config[:connection_timeout]
      EM.add_timer(timeout) do
        if @latency >= timeout
          @log.warn 'Connection timed out! closing connection'
          @state = :timeout
          @connection.close_connection
        end
      end
    end
  end
end

