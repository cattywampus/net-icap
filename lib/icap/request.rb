
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
  end

  attr_reader :method
  attr_reader :path
  attr_reader :uri

  attr_accessor :body

  def inspect
    "\#<#{self.class} #{@method}>"
  end

  def exec(socket)
    if @body
      send_request socket, @body
    else
      write_header socket
    end
  end

  private

  def send_request(socket, body)
    write_header socket
    socket.write body
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

