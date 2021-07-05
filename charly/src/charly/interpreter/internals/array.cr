require "../**"

module Charly::Internals
  # Inserts *item* at *index*
  charly_api "array_insert", TArray, BaseType, TNumeric do |array, item, index|

    # Out of bounds check
    array_size = array.value.size
    index = index.value.to_i64

    # If the index is smaller than 0, we shift to the beginning
    # If the index is bigger than the size of the array
    # we append to the end
    if index <= 0
      array.value.unshift(item)
    elsif index >= array_size
      array.value << item
    else
      array.value.insert(index, item)
    end

    return array
  end

  #  Deletes the item at *inde*
  charly_api "array_delete", TArray, TNumeric do |array, index|
    # Out of bounds check
    array_size = array.value.size
    index = index.value.to_i64

    # If the index is smaller than 0, we delete the first element
    # If the index is bigger than the size of the array
    # we delete the last item
    if array.value.size == 0
      return TNull.new
    elsif index <= 0
      return array.value.shift
    elsif index >= array.value.size
      return array.value.pop
    else
      return array.value.delete_at(index.to_i64)
    end
    return array
  end

  #  Returns a new array filled with TNull of *size*
  charly_api "array_of_size", TNumeric, BaseType do |size, value|
    return TArray.new(Array(BaseType).new(size.value.to_i64, value))
  end
end
