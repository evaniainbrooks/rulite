require 'log4r'
require 'eventmachine'
require 'bitcoin'

require_relative 'peer_address_store'

module RuLite
  class Node
    attr_reader :config
    attr_reader :log
    attr_reader :peer_connections
    attr_reader :peer_address_store
    attr_reader :last_block_time

    def initialize config, log
      @config = config
      @log = log
      
      Bitcoin.network = @config[:network]

      @peer_address_store = RuLite::PeerAddressStore.new @config[:peer_addresses_path]
    end

    def start
      @start_time = Time.now
      log.info "RuLite::Node starting"

      EM.add_shutdown_hook do
        peer_address_store.save!
        log.info "RuLite::Node exiting"
      end
    
      if !EM.epoll?
        log.error "No epoll! exiting"
        return
      end

      EM.set_descriptor_table_size(@config[:epoll_limit]).to_s if @config[:epoll_limit]
      EM.set_effective_user(@config[:epoll_user]) if @config[:epoll_user].present?
      EM.epoll = true

      listen_address, listen_port = *config[:listen]
      unless listen_address && listen_port
        log.error "No listen: [address, port] found in config file! exiting"
        return
      end

      EM.run do
        log.info "Trying to bind server socket to #{listen_address}:#{listen_port}"

        handler_params = {
          context: self,
          host: listen_host,
          port: listen_port.to_i,
          direction: :incoming
        }
        EM.start_server(listen_address, listen_port, PeerConnectionHandler, handler_params)
        log.info "Listening on #{listen_address}:#{listen_port}"
      
        connect_dns_seeds unless Bitcoin.network[:dns_seeds].empty?
        connect_config_peers unless config[:connect_peers].empty?
        connect_peers unless peer_addresses.empty?
      end
    end

    def stop!
      log.info "called stop! exiting"
      EM.stop
    end

    def connect_dns_seeds
      seed = Bitcoin.network[:dns_seeds].sample
      log.info "Connecting to DNS seed #{seed}"
      resolve_dns(seed).each do |host|
        connect_peer(host, Bitcoin.network[:default_port])
      end
    end

    def connect_known_peers
      log.info "Connecting to known nodes"
      Bitcoin.network[:known_nodes].shuffle[0..3].each do |node|
        connect_peer(node, Bitcoin.network[:default_port])
      end
    end

    def connect_config_peers
      log.info "Connecting to connect_peers from config"
      config[:connect_peers].each { |host, port| connect_peer(host, port) }
    end

    def connect_peers
      log.info "Connecting to stored peers"
      return if desired_connections <= 0

      peer_address_store.sample(desired_connections) do |addr|
        3.hours.from_now.tv_sec - addr.time
      end.each do |addr|
        connect_peer(addr.ip, addr.port)
      end
    rescue StandardError => e
      log.error "Failed to connect to peer addresses"
      log.error e.message
    end

    def connect_peer host, port
      return if @peer_connections.collect(&:host).include?(host)

      log.info "Attempting to connect to peer #{host}:#{port}"
      handler_params = {
        context: self,
        host: host,
        port: port.to_i,
        direction: :outgoing
      }
      EM.connect(host, port.to_i, PeerConnectionHandler, handler_params)
    rescue StandardError => e
      log.error "Failed to connect to peer #{host}:#{port}"
      log.error e.message
    end
    
    def desired_connections
      config[:max_outgoing_peers] - @peer_connections.select(&:outgoing?).size
    end

    def uptime
      (Time.now - @start_time).to_i
    end

  end
end
