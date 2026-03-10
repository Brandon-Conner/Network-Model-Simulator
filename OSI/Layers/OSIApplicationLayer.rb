require_relative '../../BaseNetworkLayer'
require_relative '../../ProtocolRegistryTable'
require_relative '../../HTTPSProtocolHandler'
Dir["./lib/*.rb"].each { |file| require file } # Recursively require all files in current directory


# The top-most layer in the OSI network stack.
# Data received by this layer would either be outgoing from the user of the device(https request) or incoming from a
# server(e.g, a string of HTML tags that is going to a browser application)
# Example protocols used by this layer include: HTTP, HTTPS, SMTP, POP3, IMAP, FTP, SFTP, DNS, SSH, etc...
class OSIApplicationLayer < BaseNetworkLayer

  def initialize
    @protocol_table = ProtocolRegistryTable.new
    @protocol_table.add_protocol('HTTPS', HTTPSProtocolHandler.new)
  end


  def add_header

  end

  def strip_header(data)

  end

  # This is where receiving data and moving up the stack would end, so return the data to the main control point
  def send_to_next_upper_layer(data)

  end

  #
  def send_to_next_lower_layer(data)

  end

  # This is the entry point for sending data. A check should be made to ensure that the request follows known protocol
  # formats.
  def receive_from_next_upper_layer(data)
    # Ensure the data format matches an accepted protocol format
    protocol = @protocol_table.matches_protocol?(data)
    if protocol.nil?
      log("Could not find a matching protocol for #{data}")
    else
      log("Found matching protocol for #{data} - #{protocol}")
    end



  end

  # Ensures data is correctly structured for the application.
  def receive_from_next_lower_layer(data)

  end


  def log(data)
    Output::print_with_delay("=>Log:: #{data} @ OSIApplicationLayer")
  end

end
