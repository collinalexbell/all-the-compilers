require File.expand_path('../../fixtures/classes', __FILE__)
require File.expand_path('../../fixtures/encoded_strings', __FILE__)

describe :array_join_with_default_separator, :shared => true do
  before(:each) do
    @separator = $,
  end

  after(:each) do
    $, = @separator
  end

  it "returns an empty string if the Array is empty" do
    [].send(@method).should == ''
  end

  it "returns a string formed by concatenating each String element separated by $," do
    $, = " | "
    ["1", "2", "3"].send(@method).should == "1 | 2 | 3"
  end

  it "attempts coercion via #to_str first" do
    obj = mock('foo')
    obj.should_receive(:to_str).any_number_of_times.and_return("foo")
    [obj].send(@method).should == "foo"
  end

  it "attempts coercion via #to_ary second" do
    obj = mock('foo')
    obj.should_receive(:to_str).any_number_of_times.and_return(nil)
    obj.should_receive(:to_ary).any_number_of_times.and_return(["foo"])
    [obj].send(@method).should == "foo"
  end

  it "attempts coercion via #to_s third" do
    obj = mock('foo')
    obj.should_receive(:to_str).any_number_of_times.and_return(nil)
    obj.should_receive(:to_ary).any_number_of_times.and_return(nil)
    obj.should_receive(:to_s).any_number_of_times.and_return("foo")
    [obj].send(@method).should == "foo"
  end

  it "raises a NoMethodError if an element does not respond to #to_str, #to_ary, or #to_s" do
    obj = mock('o')
    class << obj; undef :to_s; end
    lambda { [1, obj].send(@method) }.should raise_error(NoMethodError)
  end

  it "raises an ArgumentError when the Array is recursive" do
    lambda { ArraySpecs.recursive_array.send(@method) }.should raise_error(ArgumentError)
    lambda { ArraySpecs.head_recursive_array.send(@method) }.should raise_error(ArgumentError)
    lambda { ArraySpecs.empty_recursive_array.send(@method) }.should raise_error(ArgumentError)
  end

  it "taints the result if the Array is tainted and non-empty" do
    [1, 2].taint.send(@method).tainted?.should be_true
  end

  it "does not taint the result if the Array is tainted but empty" do
    [].taint.send(@method).tainted?.should be_false
  end

  it "taints the result if the result of coercing an element is tainted" do
    s = mock("taint")
    s.should_receive(:to_s).and_return("str".taint)
    [s].send(@method).tainted?.should be_true
  end

  it "untrusts the result if the Array is untrusted and non-empty" do
    [1, 2].untrust.send(@method).untrusted?.should be_true
  end

  it "does not untrust the result if the Array is untrusted but empty" do
    [].untrust.send(@method).untrusted?.should be_false
  end

  it "untrusts the result if the result of coercing an element is untrusted" do
    s = mock("untrust")
    s.should_receive(:to_s).and_return("str".untrust)
    [s].send(@method).untrusted?.should be_true
  end
end

describe :array_join_with_string_separator, :shared => true do
  it "returns a string formed by concatenating each element.to_str separated by separator" do
    obj = mock('foo')
    obj.should_receive(:to_str).and_return("foo")
    [1, 2, 3, 4, obj].send(@method, ' | ').should == '1 | 2 | 3 | 4 | foo'
  end

  it "uses the same separator with nested arrays" do
    [1, [2, [3, 4], 5], 6].send(@method, ":").should == "1:2:3:4:5:6"
    [1, [2, ArraySpecs::MyArray[3, 4], 5], 6].send(@method, ":").should == "1:2:3:4:5:6"
  end

  describe "with a tainted separator" do
    before :each do
      @sep = ":".taint
    end

    it "does not taint the result if the array is empty" do
      [].send(@method, @sep).tainted?.should be_false
    end

    ruby_bug "5902", "2.0" do
      it "does not taint the result if the array has only one element" do
        [1].send(@method, @sep).tainted?.should be_false
      end
    end

    it "taints the result if the array has two or more elements" do
      [1, 2].send(@method, @sep).tainted?.should be_true
    end
  end

  describe "with an untrusted separator" do
    before :each do
      @sep = ":".untrust
    end

    it "does not untrust the result if the array is empty" do
      [].send(@method, @sep).untrusted?.should be_false
    end

    ruby_bug "5902", "2.0" do
      it "does not untrust the result if the array has only one element" do
        [1].send(@method, @sep).untrusted?.should be_false
      end
    end

    it "untrusts the result if the array has two or more elements" do
      [1, 2].send(@method, @sep).untrusted?.should be_true
    end
  end
end
