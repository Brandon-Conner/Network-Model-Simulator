
# A model for the data that moves up/down a network stack
# Historically, this would be a header and a payload that is encapsulated as it moves down the stack, and
# decapsulated as it moves up the stack.
module ProtocolDataUnit

  def get_value
    raise NotImplementedError("#{self.class} must implement the get_value method in order to call it!!!")
  end

end


class ProtocolDataUnitUsingHash
  include ProtocolDataUnit

  def initialize(data = {})
    @data = data
  end

  def get_value(key)
    @data[key]  # Return the value associated with the provided key
  end

end



class ProtocolDataUnitUsingDelimiter
  include ProtocolDataUnit
  def initialize(delimiter, data)
    @delimiter = delimiter
    @data = data
  end

  def get_value(key)
    @data[key]
  end

end



