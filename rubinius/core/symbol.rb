class Symbol
  include Comparable

  def self.===(obj)
    Rubinius.primitive :symbol_s_eqq
    super
  end

  def encoding
    Rubinius.primitive :symbol_encoding
    raise PrimitiveFailure, "Symbol#encoding primitive failed"
  end

  def index
    Rubinius.primitive :symbol_index
    raise PrimitiveFailure, "Symbol#index primitive failed."
  end

  def is_ivar?
    Rubinius.primitive :symbol_is_ivar
    raise PrimitiveFailure, "Symbol#is_ivar primitive failed."
  end

  def is_cvar?
    Rubinius.primitive :symbol_is_cvar
    raise PrimitiveFailure, "Symbol#is_cvar primitive failed."
  end

  def is_constant?
    Rubinius.primitive :symbol_is_constant
    raise PrimitiveFailure, "Symbol#is_constant primitive failed."
  end

  def <=>(other)
    return unless other.kind_of? Symbol

    to_s <=> other.to_s
  end

  # Use equal? for == (and not Comparable version)
  alias_method :==, :equal?

  def capitalize
    to_s.capitalize.to_sym
  end

  def casecmp(other)
    return unless other.kind_of? Symbol

    to_s.casecmp(other.to_s)
  end

  def downcase
    to_s.downcase.to_sym
  end

  ##
  # Returns a pretty version of the symbol, fit for viewing
  #  :symbol.inspect #=> ":symbol"
  def inspect
    str = to_s

    case str
    when /\A(\$|@@?)[a-z_][a-z_\d]*\z/i,                      # Variable names
         /\A[a-z_][a-z_\d]*[=?!]?\z/i,                        # Method names
         /\A\$(-[a-z_\d]|[+~:?<_\/'"$.,`!;\\=*>&@]|\d+)\z/i,  # Special global variables
         /\A([|^&\/%~`!]|!=|!~|<<|>>|<=>|===?|=~|[<>]=?|[+-]@?|\*\*?|\[\]=?)\z/ # Operators
      ":#{str}"
    else
      ":#{str.inspect}"
    end
  end

  def empty?
    to_s.empty?
  end

  alias_method :intern, :to_sym
  alias_method :id2name, :to_s

  def length
    to_s.length
  end

  alias_method :size, :length

  def match(pattern)
    str = to_s

    case pattern
    when Regexp
      match_data = pattern.search_region(str, 0, str.bytesize, true)
      Regexp.last_match = match_data
      return match_data.full[0] if match_data
    when String
      raise TypeError, "type mismatch: String given"
    else
      pattern =~ str
    end
  end

  alias_method :=~, :match

  def swapcase
    to_s.swapcase.to_sym
  end

  def upcase
    to_s.upcase.to_sym
  end

  def succ
    to_s.succ.to_sym
  end

  alias_method :next, :succ

  def [](index, other = undefined)
    if index.kind_of?(Regexp)
      unless undefined.equal?(other)
        match, str = to_s.send(:subpattern, index, other)
        Regexp.last_match = match
        return str
      end

      str = to_s
      match_data = index.search_region(str, 0, str.num_bytes, true)
      Regexp.last_match = match_data
      if match_data
        result = match_data.to_s
        Rubinius::Type.infect result, index
        return result
      end
    else
      to_s[index, other]
    end
  end

  alias_method :slice, :[]

  # Returns a Proc object which respond to the given method by sym.
  def to_proc
    # Put sym in the outer enclosure so that this proc can be instance_eval'd.
    # If we used self in the block and the block is passed to instance_eval, then
    # self becomes the object instance_eval was called on. So to get around this,
    # we leave the symbol in sym and use it in the block.
    #
    sym = self
    Proc.new do |*args, &b|
      raise ArgumentError, "no receiver given" if args.empty?
      args.shift.__send__(sym, *args, &b)
    end
  end

  # Use equal? for ===
  alias_method :===, :equal?

  def self.all_symbols
    Rubinius.primitive :symbol_all_symbols
    raise PrimitiveFailure, "Symbol.all_symbols primitive failed."
  end
end
