module Rubinius
  class Splitter
    def self.split_characters(string, pattern, limit, tail_empty)
      if limit
        string.chars.take(limit - 1) << string[(limit - 1)..-1]
      else
        ret = string.chars.to_a
        # Use #byteslice because it returns the right class and taints
        # automatically. This is just appending a "", which is this
        # strange protocol if a negative limit is passed in
        ret << string.byteslice(0,0) if tail_empty
        ret
      end
    end

    def self.valid_encoding?(string)
      raise ArgumentError, "invalid byte sequence in #{string.encoding.name}" unless string.valid_encoding?
    end

    def self.split(string, pattern, limit)
      # Odd edge case
      return [] if string.empty?

      tail_empty = false

      if undefined.equal?(limit)
        limited = false
      else
        limit = Rubinius::Type.coerce_to limit, Fixnum, :to_int

        if limit > 0
          return [string.dup] if limit == 1
          limited = true
        else
          if limit < 0
            tail_empty = true
          end
          limited = false
        end
      end

      pattern ||= ($; || " ")

      if pattern == ' '
        if limited
          lim = limit
        elsif tail_empty
          lim = -1
        else
          lim = 0
        end

        return Rubinius.invoke_primitive :string_awk_split, string, lim
      elsif pattern.kind_of?(Regexp)
      else
        pattern = StringValue(pattern) unless pattern.kind_of?(String)

        valid_encoding?(string)
        valid_encoding?(pattern) 

        trim_end = !tail_empty || limit == 0

        unless limited
          if pattern.empty?
            if trim_end
              return string.chars.to_a
            end
          else
            return split_on_string(string, pattern, trim_end)
          end
        end

        pattern = Regexp.new(Regexp.quote(pattern))
      end

      # Handle // as a special case.
      if pattern.source.empty?
        return split_characters(string, pattern, limited && limit, tail_empty)
      end

      start = 0
      ret = []

      last_match = nil
      last_match_end = 0

      while match = pattern.match_from(string, start)
        break if limited && limit - ret.size <= 1

        collapsed = match.collapsing?

        unless collapsed && (match.full.at(0) == last_match_end)
          ret << match.pre_match_from(last_match_end)

          # length > 1 means there are captures
          if match.length > 1
            ret.concat(match.captures.compact)
          end
        end

        start = match.full.at(1)
        if collapsed
          start += 1
        end

        last_match = match
        last_match_end = last_match.full.at(1)
      end

      if last_match
        ret << last_match.post_match
      elsif ret.empty?
        ret << string.dup
      end

      # Trim from end
      if undefined.equal?(limit) || limit == 0
        while s = ret.at(-1) and s.empty?
          ret.pop
        end
      end

      ret
    end

    def self.split_on_string(string, pattern, trim_end)
      pos = 0

      ret = []

      pat_size = pattern.bytesize
      str_size = string.bytesize
      m = Rubinius::Mirror.reflect string

      while pos < str_size
        nxt = m.find_string(pattern, pos)
        break unless nxt

        match_size = nxt - pos
        ret << string.byteslice(pos, match_size)

        pos = nxt + pat_size
      end

      # No more separators, but we need to grab the last part still.
      ret << string.byteslice(pos, str_size - pos)

      if trim_end
        while s = ret.at(-1) and s.empty?
          ret.pop
        end
      end

      ret
    end
  end
end
