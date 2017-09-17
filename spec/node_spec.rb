require_relative '../src/node'

RSpec.describe RuLite::Node do
  describe '#initialize' do
    let(:config) { { network: :litecoin } }
    let(:log) { double }
    
    it 'loads peer addresses from the config' do
      expect_any_instance_of(RuLite::PeerAddressStore).to receive(:load!).once
      
      described_class.new config, log
    end
  end
end
