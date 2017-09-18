require 'bitcoin'
require 'log4r'

module RuLite
  class PeerEventsHandler < Bitcoin::Protocol::Handler
    def initialize connection
      @log = Log4r::Logger['rulite']
      @protocol_parser = Bitcoin::Protocol::Parser.new(self)
      @lock = Monitor.new
      @connection = connection
      @state = :new
    end
    
    def on_connected
      if @connection.incoming? && !@connection.context.accept_incoming_peers?
        @log.warn 'Not accepting any more incoming connections!'
        @state = :rejected
        @connection.close_connection
      else
        @connection.context.peer_connections << self
        @state = :handshake

        @connection.send_version
      end
    end

    def on_receive_data data
      @lock.synchronize { @protocol_parser.parse(data) }
    end

    def on_unbind
      @log.warn "#{peer} Disconnected" 
      @state = :disconnected
      @connection.context.peer_connections.delete(@connection)
    end
    
    def on_ping nonce
      @log.debug "#{peer} Received ping #{nonce}"
      @connection.send_pong(nonce)
    end

    def on_pong nonce
      @log.debug "#{peer} Received pong #{nonce}"
      if @connection.ping_nonce == nonce
        new_latency = (Time.now - @ping_time)
        @connection.latency = new_latency
      end
    end

    def on_version version
			@log.debug "#{peer} Received version #{version.inspect} message"
     
      @state = :connected
      @connection.latency = 0
			@connection.send_data(Bitcoin::Protocol.verack_pkt)
    end

		def on_verack
			@log.debug "#{peer} Received verack message"
		end

    def on_reject reject
      @log.warn "#{peer} Received reject message #{reject.inspect}"
    end

    def peer
      "#{@connection.host}:#{@connection.port}"
    end
  end
end
