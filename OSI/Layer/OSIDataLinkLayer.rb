require_relative '../../../Abstraction/eNetworkLayer'
=begin

Accepts packets from the network layer and encapsulates them into "frames,"
adding physical addresses (MAC addresses) and error-checking information (FCS)

Removes the frame header (MAC addresses) and trailer (FCS/CRC)
The NIC receives the frame and removes the physical header and trailer, checking the MAC address to ensure it
is for this device, leaving the network packet
=end

class OSIDataLinkLayer < BaseNetworkLayer

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

  # Accepts packets from the network layer and encapsulates them into "frames,"
  # adding physical addresses (MAC addresses) and error-checking information (FCS)
  def receive_from_next_lower_layer(data)

  end

  def log(data)

  end
end