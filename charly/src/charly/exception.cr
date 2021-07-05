require "./syntax/location.cr"
require "./syntax/ast.cr"
require "./source-highlight.cr"
require "./interpreter/context.cr"
require "colorize"

module Charly
  # The base for all exceptions in charly
  class BaseException < Exception
    def to_s(io)
      meta(io)
      io << "#{@message}".colorize(:red)
    end

    # :nodoc:
    private def meta(io)
    end
  end

  # `LocalException` is the base type for all exceptions that can highlight
  # parts of a file
  class LocalException < BaseException
    property location_start : Location
    property location_end : Location
    property source : String
    property filename : String
    property trace : Array(Trace)

    def initialize(@location_start, @location_end, @message, @trace = [] of Trace)
      path = @location_start.filename

      if path.starts_with? Dir.current
        @filename = File.join(".", path.gsub(Dir.current, ""))
      else
        @filename = path
      end

      # Load the file at the path of @location_start

      if File.exists?(path) && File.readable?(path)
        @source = File.read(path)
      else
        @source = ""
      end
    end

    def self.new(location_start : Location, message : String)
      self.new(location_start, location_start, message, [] of Trace)
    end

    def self.new(location_start : Location, location_end : Location, message : String)
      self.new(location_start, location_end, message, [] of Trace)
    end

    def self.new(node : ASTNode, message : String)
      self.new(node.location_start, node.location_end, message, [] of Trace)
    end

    def self.new(node : ASTNode, context : Context, message : String)
      self.new(node.location_start, node.location_end, message, context.trace)
    end

    private def meta(io)
      # Print the filename
      io << @filename.colorize(:yellow)
      io << "\n"

      # Print the source highlight
      highlighter = SourceHighlight.new(@location_start, @location_end)
      highlighter.present(source, io)

      # Print the stack trace
      @trace.each do |entry|
        io << "#{entry.colorize(:green)}\n"
      end
    end
  end

  #  A `SyntaxError` describes unexpected chars or tokens in the source string
  class SyntaxError < LocalException
  end

  # A `InvalidNode` describes unexpected nodes in a parse tree
  class RunTimeError < LocalException
  end

  # A `UnlocatedRunTimeError` happens on a RunTimeError when there is no
  #  location information to associate with it
  class UnlocatedRunTimeError < BaseException
    property trace : Array(Trace)

    def initialize(@message : String, @trace)
    end

    private def meta(io)
      @trace.each do |entry|
        io << "#{entry.colorize(:green)}\n"
      end
    end
  end
end
