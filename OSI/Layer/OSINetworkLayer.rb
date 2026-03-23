require_relative '../../Abstraction/NetworkLayer'

=begin
Accepts segments or datagrams from the transport layer and encapsulates them into "packets," adding logical addressing (IP addresses) for routing

The router/device removes the IP header (source/destination IP) to determine the next destination, leaving the transport segment
Removes the packet header (IP addresses).
=end

class OSINetworkLayer < BaseNetworkLayer

  def initialize

  end


  def encapsulate(data)

  end

  def decapsulate(data)

  end

  def send_to_next_upper_layer(data)

  end

  def send_to_next_lower_layer(data)

  end

  def receive_from_next_upper_layer(data)

  end

  def receive_from_next_lower_layer(data)

  end

  def log(data)

  end
end