
=begin
  Formally - Accepts data from the application layer to be formatted, encrypted, or compressed
    (e.g., converting ASCII, JSON, or formatting encrypted SSL/TLS data).
  For this simulation - Ensure that the data is in UTF-8 format. Since Ruby encodes in UTF-8 by default, nothing actually
    need to be done.
=end


require_relative '../BaseNetworkLayer'
require_relative '../Output'

class OSIPresentationLayer < BaseNetworkLayer


  def initialize

  end

  def add_header

  end

  def strip_header(data)

  end

  def send_to_next_upper_layer(data)

  end

  def send_to_next_lower_layer(data)

  end

  # When data is received from the application layer(sending data)
  def receive_from_next_upper_layer(data)
    log("Received by Presentation layer")
    check_for_utf8(data)
  end

  def check_for_utf8(data)
    log("Data is formatted in UTF-8")
  end

  def receive_from_next_lower_layer(data)

  end


  def log(data)
    Output::print_with_delay(data)
  end
end