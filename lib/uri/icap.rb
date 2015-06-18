
require 'uri/generic'

module URI
  class ICAP < Generic

    #
    # A Default port of 1344 for URI::ICAP
    #
    DEFAULT_PORT = 1344

    #
    # An Array of the available components for URI::ICAP
    #
    COMPONENT = [
      :scheme,
      :userinfo, :host, :port,
      :path,
      :query
    ].freeze

    #
    # == Description
    #
    # Create a new URI::ICAP object from components, with syntax checking.
    # The components accepted are userinfo, host, port, path, and query.
    # The components should be provided either as an Array, or as a Hash
    # with keys formed by preceding the component names with a colon.
    # If an Array is used, the components must be passed in the order
    # [userinfo, host, port, path, query].
    #
    # Example:
    #
    #     newuri = URI::ICAP.build({:host => 'www.example.com',
    #       :path => '/foo/bar'})
    #
    #     newuri = URI::ICAP.build([nil, "www.example.com", nil, "/path",
    #       "query"])
    #
    def self.build(args)
      tmp = Util::make_components_hash(self, args)
      return super(tmp)
    end

    #
    # == Description
    #
    # Create a new URI::ICAP object from generic URI components as per
    # RFC 2396. Arguments are +scheme+, +userinfo+, +host+, +port+, +registry+,
    # +path+, +opaque+, and +query+, in that order.
    def initialize(*arg)
      super(*arg)
    end

    alias_method :hostname, :host unless self.instance_methods.include?(:hostname)
  end

  @@schemes['ICAP'] = ICAP
end

