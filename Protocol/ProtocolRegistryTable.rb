
# Data Structure for a protocol registry table. Represented by an initially empty hash.
# The Protocol Registry Table provides a lookup for all accepted types of input for a layer.
# When an input is to be sent as data in a simulation, the input is parsed to check if the format
# matches an entries regular expression in the table.
class ProtocolRegistryTable


  def initialize
    @hash = {}
  end


  def add_protocol(id, protocol)
    @hash[id] = protocol
  end


  def remove_protocol(id)
    @hash.delete(id)
  end


  def get_protocol(id)
    @hash[id]
  end

  def matches_protocol?(data)
    @hash.each do |id, protocol|
      if protocol.matches?(data)
        return id
      end
    end
    return nil
  end

end