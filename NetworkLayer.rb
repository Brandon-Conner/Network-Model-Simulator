

=begin
  Interface contract for a specific layer in a network stack
  - Must implement send, receive and log functions
=end
module NetworkLayer

  # Implement this to add header info(used when sending downwards in the stack)     - Encapsulation
  def add_header
    raise NotImplementedError, "#{self.class} must implement #add_header function in order to call it!"
  end
  # Implement this to strip header info(used when sending upwards in the stack)       - Decapsulation
  def strip_header
    raise NotImplementedError, "#{self.class} must implement #strip_header function in order to call it!"
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