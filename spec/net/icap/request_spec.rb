require 'byebug'

module Net
  RSpec.describe ICAPRequest do
    let(:uri) { URI('icap://localhost/echo') }

    it "creates a request with a method and path" do
      request = ICAPRequest.new 'METHOD', false, uri
      expect(request.method).to eq 'METHOD'
    end

    it "creates a request with a uri" do
      request = ICAPRequest.new 'METHOD', false, uri
      expect(request.uri).to eq uri
    end

    it "expects a response without a body" do
      request = ICAPRequest.new 'METHOD', false, uri
      expect(request.response_body_permitted?).to be_falsey
    end

    it "expects a response with a body" do
      request = ICAPRequest.new 'METHOD', true, uri
      expect(request.response_body_permitted?).to be_truthy
    end

    it "creates a request with a header" do
      request = ICAPRequest.new 'METHOD', false, uri, { 'encapsulated' => 'req-hdr=0' }
      expect(request['encapsulated']).to eq 'req-hdr=0'
    end

    it "can set an ICAP header" do
      request = ICAPRequest.new 'METHOD', false, uri
      request['encapsulated'] = 'res-body=0'
      expect(request['encapsulated']).to eq 'res-body=0'
    end

    it "defaults header User-Agent to Ruby" do
      request = ICAPRequest.new 'METHOD', false, uri
      expect(request['user-agent']).to eq 'Ruby'
    end

    it "sets header Host from uri" do
      request = ICAPRequest.new 'METHOD', false, uri
      expect(request['host']).to eq 'localhost'
    end

    it "header Host includes hostname and non-default port" do
      request = ICAPRequest.new 'METHOD', false, URI('icap://anyhost:1234/service')
      expect(request['host']).to eq 'anyhost:1234'
    end

    it "parses Preview from header" do
      request = ICAPRequest.new 'METHOD', false, uri, { 'preview' => '100' }
      expect(request.preview).to eq 100
    end

    it "raises error when Preview is invalid" do
      request = ICAPRequest.new 'METHOD', false, uri, { 'preview' => 'invalid' }
      expect { request.preview }.to raise_error(Net::ICAPHeaderSyntaxError)
    end

    it "writes a simple header to the socket" do
      request = ICAPRequest.new 'OPTIONS', false, uri
      io = StringIO.new
      request.send(:write_header, io)
      expect(io.string).to eq "OPTIONS #{uri.to_s} ICAP/1.0\r\nHost: localhost\r\nUser-Agent: Ruby\r\n\r\n"
    end
  end

  RSpec.describe ICAP::Options do
    it "sets the request method to OPTIONS" do
      request = ICAP::Options.new 'path'
      expect(request.method).to eq 'OPTIONS'
    end
  end

  RSpec.describe ICAP::Respmod do
    it "sets the request method to RESPMOD" do
      request = ICAP::Respmod.new 'path'
      expect(request.method).to eq 'RESPMOD'
    end
  end

  RSpec.describe ICAP::Reqmod do
    it "sets the request method to REQMOD" do
      request = ICAP::Reqmod.new 'path'
      expect(request.method).to eq 'REQMOD'
    end
  end
end

