
class Net::ICAPRequest

  include Net::HTTPHeader

  def initialize(method, resbody, uri, initheader = nil)
    @method = method
    @response_has_body = resbody
    @body = nil

    case uri
    when URI
      @uri = uri.dup
    when String
      @uri = URI(uri)
    end
    host = @uri.hostname
    host += ":#{@uri.port}" if @uri.port != @uri.class::DEFAULT_PORT

    initialize_http_header initheader
    self['Host'] ||= host
    self['User-Agent'] ||= 'Ruby'
  end

  attr_reader :method
  attr_reader :uri

  attr_accessor :body

  def response_body_permitted?
    @response_has_body
  end

  def exec(sock)
    if @uri
      if @uri.port == @uri.default_port
        self['host'] = @uri.host
      else
        self['host'] = "#{@uri.host}:#{@uri.port}"
      end
    end

    if @body
      if preview
        send_request_with_preview sock, @body
      else
        send_request_with_body sock, @body
      end
    else
      write_header sock
    end
  end

  def preview
    return nil unless key?('Preview')
    preview = self['Preview'].slice(/\d+/) or
        raise Net::ICAPHeaderSyntaxError, 'wrong Preview format'
    preview.to_i
  end

  def update_uri(host, port)
    @uri.host ||= host
    @uri.port = port

    @uri
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

  def send_request_with_body(sock, body)
    write_header(sock)
    chunker = Chunker.new(sock)
    chunker.write(body)
    chunker.finish
  end

  def send_request_with_preview(sock, body)
    write_header(sock)
    chunker = Chunker.new(sock)
    chunker.write(body[0,preview])
    chunker.finish
    res = wait_for_continue(sock)
    chunker.write(body[preview, body.length-preview])
    chunker.finish
  end

  def wait_for_continue(sock)
    res = nil
    if IO.select([sock.io], nil, nil, sock.continue_timeout)
      res = Net::ICAPResponse.read_new(sock)
      unless res.kind_of?(Net::ICAPContinue)
        throw :response, res
      end
    end
    res
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

class Net::ICAP::Options < Net::ICAPRequest
  def initialize(uri, initheader = nil)
    super('OPTIONS', false, uri, initheader)
  end
end

class Net::ICAP::Respmod < Net::ICAPRequest
  def initialize(uri, initheader = nil)
    super('RESPMOD', true, uri, initheader)
  end
end

class Net::ICAP::Reqmod < Net::ICAPRequest
  def initialize(uri, initheader = nil)
    super('REQMOD', true, uri, initheader)
  end
end

