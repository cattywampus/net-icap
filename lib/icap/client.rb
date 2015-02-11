require 'socket'
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
    end

    def inspect
      "#<#{self.class} #{@address}:#{@port}>"
    end

    def connect
      s = Timeout.timeout(@open_timeout, Net::OpenTimeout) {
        begin
          TCPSocket.open(address, port)
        rescue => e
          raise e, "Failed to open TCP connection to " +
            "#{address}:#{port} (#{e.message})"
        end
      }
      @socket = Net::BufferedIO.new(s)
    end
    private :connect

    def finish
      @socket.close if @socket and not @socket.closed?
      @socket = nil
    end

    def options(service, params = {})
      uri = URI("icap:\/\/#{address}:#{port}\/#{service.gsub(/^\//, '')}?#{to_query(params)}")
      req  = ICAP::Request.new('OPTIONS', uri,)
      request(req)
    end

    def request(req, body = nil, &block)
      connect
      req.exec(@socket)
      response = ICAP::Response.read_new(@socket)
      finish

      response
    end

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
