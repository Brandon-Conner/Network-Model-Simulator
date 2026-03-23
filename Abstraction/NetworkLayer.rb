

=begin
  Interface contract for a specific layer in a network stack
  - Must implement send, receive and log functions
=end
module NetworkLayer

  # Implement this to encapsulate data (add header info when sending downwards in the stack)
  def encapsulate(data)
    raise NotImplementedError, "#{self.class} must implement #encapsulate function in order to call it!"
  end
  # Implement this to decapsulate data (strip header info when sending upwards in the stack)
  def decapsulate(data)
    raise NotImplementedError, "#{self.class} must implement #decapsulate function in order to call it!"
  end

  # Send to the next layer above this one in the stack
  def send_to_next_upper_layer
    raise NotImplementedError, "#{self.class} must implement #send_to_next_upper_layer function in order to call it!"
  end

  # Send to the next layer below this one in the stack
  def send_to_next_lower_layer
    raise NotImplementedError, "#{self.class} must implement #send_to_next_lower_layer function in order to call it!"
  end

  # Receive from the next layer above this one in the stack
  def receive_from_next_upper_layer
    raise NotImplementedError, "#{self.class} must implement #receive_from_next_upper_layer function in order to call it!"
  end

  # Receive from the next layer below this one in the stack
  def receive_from_next_lower_layer
    raise NotImplementedError, "#{self.class} must implement #receive_from_next_lower_layer function in order to call it!"
  end

  # Implement to add logs for this layer
  def log
    raise NotImplementedError, "#{self.class} must implement #log function in order to call it!"
  end


end