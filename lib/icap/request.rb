
class ICAP::Request

  include ICAP::Header

  attr_reader :method

  def initialize(method, uri_or_path, initheader = nil)
    @method = method

    if URI === uri_or_path
      @uri = uri_or_path.dup
      host = @uri.hostname.dup
      host << ":".freeze << @uri.port.to_s if @uri.port != @uri.default_port
      @path = uri_or_path.path
      raise ArgumentError, "no ICAP resource path given" unless @path
    else
      @uri = nil
      host = nil
      raise ArgumentError, "no ICAP resource path given" unless uri_or_path
      raise ArgumentError, "ICAP resource path is empty" if uri_or_path.empty?
      @path = uri_or_path.dup
    end

    initialize_icap_header initheader
    self['User-Agent'] ||= 'Ruby'
    self['Host'] ||= host if host

    @body = nil
    
    @preview = nil
  end

  attr_reader :method
  attr_reader :path
  attr_reader :uri

  attr_accessor :body
  
  attr_reader :preview
  
  def inspect
    "\#<#{self.class} #{@method}>"
  end

  def exec(socket)
    if @body
      send_header(socket)
      send_body(socket, @body)
    else
      write_header(socket)
    end
  end
  
  def continue(socket, body)
    send_body(socket, body)
  end

  def preview=(bytes)
    raise ArgumentError, "ICAP Preview #{bytes || 'nil'} bytes must be >= 0" if bytes.nil? || bytes < 0
    @preview = self['preview'] = bytes
  end
  
  private
  
  class Chunker #:nodoc:
    def initialize(sock)
      @sock = sock
      @prev = nil
    end

    def write(buf)
      # avoid memcpy() of buf, buf can huge and eat memory bandwidth
      @sock.write("#{buf.bytesize.to_s(16)}\r\n")
      rv = @sock.write(buf)
      @sock.write("\r\n")
      rv
    end

    def finish
      @sock.write("0\r\n\r\n")
    end
  end
  
  def send_body(socket, body)
    chunker = Chunker.new(socket)
    chunker.write(body)
    chunker.finish
  end
  
  def send_header(socket)
    self['Encapsulated'] = 'res-body=0'
    write_header(socket)
  end

  def write_header(socket)
    buf = "#{@method} #{@uri} ICAP/1.0\r\n"
    each_capitalized do |key, value|
      buf << "#{key}: #{value}\r\n"
    end
    buf << "\r\n"
    socket.write buf
  end
end

