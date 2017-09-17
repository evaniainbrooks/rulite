require 'yaml'
require 'fileutils'

module RuLite
  class PeerAddressStore
    def initialize store_path
      @store_path = store_path
      @peer_addresses = [] 

      self.load!
    end

    def sample count, &block
      return @peer_addresses.sample(count, block)
    end

    def add peer

    end

    def empty?
      @peer_addresses.empty?
    end

    def load!
      if !File.exist?(store_path)
        FileUtils.mkdir_p(File.dirname(store_path))
        return []
      end

      yaml_addresses = YAML.load_file(store_path) 
      yaml_addresses.collect do |addr|
        Bitcoin::Protocol::Addr.new.tap do |o|
          o.time = addr[:time]
          o.ip = addr[:ip]
          o.port = addr[:port]
          p.service = addr[:service]
        end
      end
    rescue StandardError => e
      log.error "Failed to load peer_addresses file"
      log.error e.message
      return []
    end

    def save! 
      return if peer_addresses.empty?

      FileUtils.mkdir_p(File.dirname(store_path))

      peers_as_hash = peer_addresses.map do |peer|
        Hash[[:time, :service, :ip, :port].zip(peer.entries)] rescue nil
      end.compact

      File.open(peers_file, 'w') do |f| 
        f.write peers_as_hash
        f.close
      end
      log.info "Stored peer addresses to #{store_path}"
    rescue StandardError => e
      log.error "Failed to store peer addresses to #{store_path}"
      log.error e.message
    end
  end
end
