require "./container.cr"
require "../syntax/ast.cr"

module Charly
  # The basetype of all types in charly
  abstract class BaseType
    abstract def name(io) : String

    def to_s(io)
      name(io)
    end

    def self.to_s(io)
      self.name(io)
    end

    def self.name(io)
      io << "BaseType"
    end

    # Creates a new BaseType from an ASTNode
    #
    # ```
    # BaseType.from(NumericLiteral.new(5)) # => TNumeric(@value=5)
    # ```
    def self.from(node : ASTNode)
      unless AST.is_primitive node
        raise "#{node.class} does not represent a primitive type"
      end

      case node
      when NumericLiteral
        return TNumeric.new node.value.to_f64
      when StringLiteral
        return TString.new node.value
      when BooleanLiteral
        return TBoolean.new node.value
      when NullLiteral
        return TNull.new
      when NANLiteral
        return TNumeric.new Float64::NAN
      else
        raise "#{node.class} not implemented in BaseType#from"
      end
    end
  end

  # The basetype of all types in charly that have their own data scope
  # Objects, Classes, Functions, etc.
  abstract class DataType < BaseType
    property data : Scope

    def initialize
      super()
      @data = Scope.new
    end

    def initialize
      super()
      @data = Scope.new
      yield @data
    end
  end

  # The basetype of all types in charly that don't have their own data scope
  # Numeric, String, Boolean, Array
  abstract class PrimitiveType(T) < BaseType
    property value : T

    def initialize(@value : T)
      super()
    end
  end

  # Numeric
  class TNumeric < PrimitiveType(Float64)
    def self.new(value : Number)
      self.new(value.to_f64)
    end

    def name(io)
      if @value.nan?
        io << "NAN"
      else
        if @value % 1 == 0
          io << @value.to_i64
        else
          io << @value
        end
      end
    end

    def self.name(io)
      io << "Numeric"
    end
  end

  # Strings
  class TString < PrimitiveType(String)
    def name(io)
      io << @value
    end

    def self.name(io)
      io << "String"
    end
  end

  # Booleans
  class TBoolean < PrimitiveType(Bool)
    def name(io)
      io << @value ? "true" : "false"
    end

    def self.name(io)
      io << "Boolean"
    end
  end

  # An array of BaseTypes
  class TArray < PrimitiveType(Array(BaseType))

    def self.new
      self.new [] of BaseType
    end

    def name(io)
      io << "Array:#{@value.size}"
    end

    def self.name(io)
      io << "Array"
    end
  end

  # The null type
  class TNull < BaseType
    def name(io)
      io << "null"
    end

    def self.name(io)
      io << "Null"
    end
  end

  # An object
  class TObject < DataType
    def name(io)
      io << "Object"
    end

    def self.name(io)
      io << "Object"
    end
  end

  # A class
  class TClass < DataType
    property name : String
    property properties : Array(IdentifierLiteral)
    property methods : Array(FunctionLiteral)
    property parents : Array(TClass)
    property parent_scope : Scope

    def initialize(@name, @properties, @methods, @parents, @parent_scope)
      super()
    end

    def name(io)
      io << "Class:#{@parents.size}"
    end

    def self.name(io)
      io << "Class"
    end
  end

  # A primitive type
  class TPrimitiveClass < DataType
    property name : String
    property parent_scope : Scope
    property methods : Scope

    def initialize(@name, @methods, @parent_scope)
      super()
    end

    def name(io)
      io << "PrimitiveClass:#{@name}"
    end

    def self.name(io)
      io << "PrimitiveClass"
    end
  end

  # A regular function
  class TFunc < DataType
    property name : String
    property argumentlist : IdentifierList
    property block : Block
    property parent_scope : Scope
    property bound_context : BaseType?
    property bound_arguments : Array(BaseType)

    def initialize(@name, @argumentlist, @block, @parent_scope)
      super()
      @bound_arguments = [] of BaseType
    end

    def name(io)
      io << "Function:#{@argumentlist.children.size}"
    end

    def self.name(io)
      io << "Function"
    end
  end

  # A bound internal method
  class TInternalFunc < DataType
    property name : String

    def initialize(@name)
      super()
    end

    def name(io)
      io << "Function"
    end

    def self.name(io)
      io << "Function"
    end
  end
end
