class ICAP::Response
  
  class << self
    def read_new(socket)
      code, message = read_status_line(socket)
      response = ICAP::Response.new(code, message)
      each_response_header(socket) do |key, value|
        response.add_field(key, value)
      end
      response
    end
    
    private
    
    def read_status_line(socket)
      status = socket.readline
      puts "response status = #{status}"
      m = /\AICAP\/1\.0\s+(\d\d\d)(?:\s+(.*))?\z/in.match(status)
      m.captures
    end
    
    def each_response_header(sock)
      key = value = nil
      while true
        line = sock.readuntil("\n", true).sub(/\s+\z/, '')
        break if line.empty?
        if line[0] == ?\s or line[0] == ?\t and value
          value << ' ' unless value.empty?
          value << line.strip
        else
          yield key, value if key
          key, value = line.strip.split(/\s*:\s*/, 2)
          raise Net::HTTPBadResponse, 'wrong header line format' if value.nil?
        end
      end
      yield key, value if key
    end
  end
  
  include ICAP::Header
  
  def initialize(code, message)
    @code = code
    @message = message
    initialize_icap_header nil
  end
  
  attr_reader :code
  
  attr_reader :message
  
  
end