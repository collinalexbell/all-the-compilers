class RaiseExceptionMatcher
  def initialize(exception, message, &block)
    @exception = exception
    @message = message
    @block = block
  end

  def matches?(proc)
    @result = proc.call
    return false
  rescue Object => @actual
    return false unless @actual.instance_of? @exception
    if @message then
      case @message
      when String then
        return false if @message != @actual.message
      when Regexp then
        return false if @message !~ @actual.message
      end
    end

    @block[@actual] if @block

    return true
  end

  def failure_message
    message = ["Expected #{@exception}#{%[ (#{@message})] if @message}"]

    if @actual then
      message << "but got #{@actual.class}#{%[ (#{@actual.message})] if @actual.message}"
    else
      message << "but no exception was raised (#@result was returned)"
    end

    message
  end

  def negative_failure_message
    message = ["Expected to not get #{@exception}#{%[ (#{@message})] if @message}", ""]
    message[1] = "but got #{@actual.class}#{%[ (#{@actual.message})] if @actual.message}" unless @actual.class == @exception
    message
  end
end

class Object
  def raise_exception(exception=Exception, message=nil, &block)
    RaiseExceptionMatcher.new(exception, message, &block)
  end
end

