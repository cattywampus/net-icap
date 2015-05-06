require 'byebug'

module Net
  class ICAPBadResponse < StandardError; end
  class ICAPHeaderSyntaxError < StandardError; end

  class ICAP
    def ICAP.default_port
      1344
    end

    def initialize(address, port = nil)
      @address = address
      @port = (port || ICAP.default_port)
      @started = false
      @socket = nil
    end

    attr_reader :address
    attr_reader :port

    def set_debug_output(output)
      @debug_output = output
    end

    def started?
      @started
    end

    def start
      raise IOError, 'ICAP session already opened' if @started
      if block_given?
        begin
          do_start
          return yield(self)
        ensure
          do_finish
        end
      end
      do_start
      self
    end

    def do_start
      connect
      @started = true
    end
    private :do_start

    def connect
      D "opening connection to #{address}:#{port}..."
      s = TCPSocket.open(address, port)
      D "opened"
      @socket = BufferedIO.new(s)
      @socket.debug_output = @debug_output
    end
    private :connect

    def finish
      raise IOError, 'ICAP session not yet started' unless started?
      do_finish
    end

    def do_finish
      @started = false
      @socket.close if @socket and not @socket.closed?
      @socket = nil
    end
    private :do_finish

    def request_options(service, initheader = nil)
      request(Options.new(uri(service), initheader))
    end

    def request_respmod(service, body, initheader = nil, &block)
      request(Respmod.new(uri(service), initheader), body, &block)
    end

    def request(req, body = nil, &block)
      unless started?
        start {
          return request(req, body, &block)
        }
      end

      req.body = body

      transport_request(req, &block)
    end

    def uri(path)
      path = '/' + path unless path[0] == '/'
      URI::ICAP.build hostname: address, port: port, path: path
    end

    private

    def transport_request(req)
      begin_transport(req)

      req.exec(@socket)
      res = ICAPResponse.read_new(@socket)
      res.uri = req.uri
      res.reading_body(@socket, req.response_body_permitted?) {
        yield res if block_given?
      }

      end_transport(req, res)
      res
    rescue => exception
      D "Conn close because of error #{exception}"
      @socket.close if @socket and not @socket.closed?
      raise exception
    end

    def begin_transport(req)
      connect if @socket.closed?

      host = req['host'] || address
      req.update_uri host, port
    end

    def end_transport(req, res)
      if @socket.closed?
        D 'Conn socket closed'
      else
        D 'Conn close'
        @socket.close
      end
    end

    def addr_port
      address + (port == ICAP.default_port ? '' : ":#{port}")
    end

    def D(msg)
      return unless @debug_output
      @debug_output << msg
      @debug_output << "\n"
    end
  end
end

require 'uri/icap'

require 'net/http/header'

require 'net/icap/request'

require 'net/icap/response'
require 'net/icap/responses'


