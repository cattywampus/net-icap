module ICAP::Header
  def initialize_icap_header(initheader)
    @header = {}
    return unless initheader
    initheader.each do |key, value|
      warn "icap: warning: duplicated ICAP header: #{key}" if key?(key)
      @header[key.downcase] = [value.strip]
    end
  end

  # Returns the header field corresponding to the case-insensitive key.
  # For example, a key of "Preview" might return "1024".
  def [](key)
    a = @header[key.downcase] or return nil
    a.join(', ')
  end

  # Sets the header field corresponding to the case-insensitive key.
  def []=(key, val)
    unless val
      @header.delete key.downcase
      return val
    end
    @header[key.downcase] = [val]
  end
  
  # [Ruby 1.8.3]
  # Adds a value to a named header field, instead of replacing its value.
  # Second argument +val+ must be a String.
  # See also #[]=, #[] and #get_fields.
  #
  #   request.add_field 'X-My-Header', 'a'
  #   p request['X-My-Header']              #=> "a"
  #   p request.get_fields('X-My-Header')   #=> ["a"]
  #   request.add_field 'X-My-Header', 'b'
  #   p request['X-My-Header']              #=> "a, b"
  #   p request.get_fields('X-My-Header')   #=> ["a", "b"]
  #   request.add_field 'X-My-Header', 'c'
  #   p request['X-My-Header']              #=> "a, b, c"
  #   p request.get_fields('X-My-Header')   #=> ["a", "b", "c"]
  #
  def add_field(key, val)
    if @header.key?(key.downcase)
      @header[key.downcase].push val
    else
      @header[key.downcase] = [val]
    end
  end
  
  # Iterates through the header names and values, passing in the name
  # and value to the code block supplied
  #
  # Example:
  #
  #     response.header.each_header { |key, value| puts "#{key} = #{value}" }
  #
  def each_header
    block_given? or return enum_for(__method__)
    @header.each do |key, value|
      yield key, value.join(', ')
    end
  end
  alias each each_header

  # Iterates through the header names in the header, passing
  # each header name to the code block.
  def each_name(&block)
    block_given? or return enum_for(__method__)
    @header.each_key(&block)
  end
  alias each_key each_name

  # Iterates through the header names in the header, passing
  # capitalized header names to the code block.
  #
  # Note that header names are capitalized systematically;
  # capitalization may not match that used by the remote HTTP
  # server in its response.
  def each_capitalized_name
    block_given? or return enum_for(__method__)
    @header.each_key do |key|
      yield capitalize(key)
    end
  end

  # Iterates through header values, passing each value to the
  # code block.
  def each_value
    block_given? or return enum_for(__method__)
    @header.each_value do |value|
      yield value.join(', ')
    end
  end

  # Removes a header field, specified by case-insensitive key.
  def delete(key)
    @header.delete(key.downcase)
  end

  # true if +key+ header exists
  def key?(key)
    @header.key?(key.downcase)
  end

  # Returns a Hash consisting of header names and array of values.
  # e.g.
  # {"options-ttl" => ["3600"],
  #  "preview" => ["1024"],
  #  "date" => ["Mon, 09 Feb 2015 21:30:00 GMT"]}
  def to_hash
    @header.dup
  end

  # As for #each_header, except the keys are provided in capitalized form.
  #
  # Note that header names are capitalized systematically;
  # capitalization may not match that used by the remote HTTP
  # server in its response.
  def each_capitalized
    block_given? or return enum_for(__method__)
    @header.each do |key, value|
      yield capitalize(key), value.join(', ')
    end
  end
  alias canonical_each each_capitalized

  def capitalize(name)
    name.to_s.split(/-/).map { |s| s.capitalize }.join('-')
  end
  private :capitalize

end

