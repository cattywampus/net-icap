module Net
  RSpec.describe ICAPResponse do
    SUCCESS_STATUS = "ICAP/1.0 200 OK"
    it "reads code from status line" do
      io = StringIO.new SUCCESS_STATUS
      code, _ = ICAPResponse.send(:read_status_line, io)
      expect(code).to eq '200'
    end

    it "reads message from status line" do
      io = StringIO.new SUCCESS_STATUS
      _, msg = ICAPResponse.send(:read_status_line, io)
      expect(msg).to eq 'OK'
    end

  end
end

