require 'net/protocol'
require 'uri'

module ICAP
  class Client
    attr_reader :address, :port

    # Number of seconds to wait for the connection to open. The default
    # value is +nil+.
    attr_accessor :open_timeout

    # Creates a new ICAP::Client object for the specified server address,
    # without opening the TCP connection or initializing the ICAP session.
    # The +address+ should be a DNS hostname or IP address.
    def initialize(address, port = nil)
      @address = address
      @port = (port || ICAP.default_port)

      @open_timeout = nil
      @started = false
      @socket = nil
      @started = false
    end

    def inspect
      "#<#{self.class} #{@address}:#{@port} open=#{started?}>"
    end

    def started?
      @started
    end

    # Opens a TCP connection and ICAP session.
    #
    # When this method is called with a block, it passes the ICAP::Client
    # object to the block, and closes the TCP connection and ICAP session
    # after the block has been executed.
    #
    # When called with a block, it returns the return value of the
    # block; otherwise, it returns self.
    #
    def start  # :yield: http
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
      s = Timeout.timeout(@open_timeout, ::Net::OpenTimeout) {
        begin
          TCPSocket.open(address, port)
        rescue => e
          raise e, "Failed to open TCP connection to " +
            "#{address}:#{port} (#{e.message})"
        end
      }
      @socket = ::Net::BufferedIO.new(s)
    end
    private :connect

    # Finishes the ICAP session and closes the TCP connection.
    # Raises IOError if the session has not been started.
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

    def options(service, params = {})
      req  = ICAP::Request.new('OPTIONS', uri(service, params))
      start do |icap|
        icap.request(req)
      end
    end

    def respmod(service, body = nil, preview_size = nil, params = {})
      req = ICAP::Request.new('RESPMOD', uri(service, params))
      start do |icap|
        if preview_size && preview_size < body.size
          req.preview = preview_size
          req.body = body[0,preview_size]
          preview_response = icap.request(req)
          if preview_response.code == "100"
            req.continue(@socket, body[preview_size,body.size-preview_size])
            ICAP::Response.read_new(@socket)
          else
            preview_response
          end
        else
          req.body = body
          request(req)
        end
      end
    end

    def request(req, body = nil, &block)
      req.exec(@socket)
      ICAP::Response.read_new(@socket)
    end

    def uri(service, params)
      URI("icap:\/\/#{address}:#{port}\/#{service.gsub(/^\//, '')}?#{to_query(params)}")
    end
    private :uri

    def to_query(params)
      params.collect { |key, value| encode(key, value) }.sort.join('&')
    end
    private :to_query

    def encode(key, value)
      require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
      "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
    end
    private :encode
  end
end
