require 'byebug'

class Net::ICAPResponse
  class << self
    def body_permitted?
      self::HAS_BODY
    end

    def read_new(sock)
      code, msg = read_status_line(sock)
      res = response_class(code).new(code, msg)
      each_response_header(sock) do |k, v|
        res.add_field k, v
      end
      res
    end

    private

    def read_status_line(sock)
      status = sock.readline
      m = /\AICAP\/1\.0\s+(\d\d\d)(?:\s+(.*))?\z/in.match(status)
      m.captures
    end

    def response_class(code)
      CODE_TO_OBJ[code] or
      CODE_CLASS_TO_OBJ[code[0,1]] or
      Net::ICAPUnknownResponse
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
          raise Net::ICAPBadResponse, 'wrong header line format' if value.nil?
        end
      end
      yield key, value if key
    end
  end

  public

  include Net::HTTPHeader

  def initialize(code, msg)
    @code = code
    @message = msg

    initialize_http_header nil
  end

  attr_reader :code
  attr_reader :message

  attr_accessor :uri

  def reading_body(sock, reqmethodallowbody)
    @socket = sock
    @body_exist = reqmethodallowbody && self.class.body_permitted?
    begin
      yield
      self.body
    ensure
      @socket = nil
    end
  end

  def read_body(dest = nil, &block)
    if @read
      raise IOError, "#{self.class}\#read_body called twice" if dest or block
      return @body
    end
    to = procdest(dest, block)
    stream_check
    if @body_exist
      read_body_0 to
      @body = to
    else
      @body = nil
    end
    @read = true

    @body
  end

  def body
    read_body()
  end

  def body=(value)
    @body = value
  end

  private

  def read_body_0(dest)
    if self['encapsulated'] && self['encapsulated'] =~ /res-body=(\d+)/
      hdr_size = $1.to_i
      @socket.read hdr_size, dest
      read_chunked dest, @socket
    else
      @socket.read_all dest
    end
  end

  def read_chunked(dest, chunk_data_io) # :nodoc:
    total = 0
    while true
      line = @socket.readline
      hexlen = line.slice(/[0-9a-fA-F]+/) or
          raise Net::HTTPBadResponse, "wrong chunk size line: #{line}"
      len = hexlen.hex
      break if len == 0
      begin
        chunk_data_io.read len, dest
      ensure
        total += len
        @socket.read 2   # \r\n
      end
    end
    until @socket.readline.empty?
      # none
    end
  end


  def stream_check
    raise IOError, 'attempt to read body out of block' if @socket.closed?
  end

  def procdest(dest, block)
    raise ArgumentError, 'both arg and block given for HTTP method' if
        dest and block
    if block
      Net::ReadAdapter.new(block)
    else
      dest || ''
    end
  end
end

