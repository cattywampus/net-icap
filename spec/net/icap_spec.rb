module Net
  RSpec.describe ICAP do

    it "has a default port" do
      expect(ICAP.default_port).to eq 1344
    end

    it "can be instantiated with an address" do
      icap = ICAP.new 'localhost'
      expect(icap.address).to eq 'localhost'
    end

    it "uses the default ICAP port" do
      icap = ICAP.new 'localhost'
      expect(icap.port).to eq 1344
    end

    it "can be instantiated with a port" do
      icap = ICAP.new 'localhost', 1234
      expect(icap.port).to eq 1234
    end

    it "is not started when created" do
      icap = ICAP.new 'localhost'
      expect(icap.started?).to be_falsey
    end

    it "makes an OPTIONS request" do
      icap = ICAP.new 'localhost'
      icap.set_debug_output($stdout)
      response = icap.request_options 'echo'

      expect(response).to be_a Net::ICAPOK
    end

    it "makes a RESPMOD request" do
      virus = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
      icap = ICAP.new 'localhost'
      icap.set_debug_output($stdout)
      response = icap.request_respmod 'avscan', virus, { 'encapsulated' => 'res-body=0' }
      expect(response.body).not_to be_nil
    end
  end
end
