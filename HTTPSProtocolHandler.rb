=begin
The HTTPS protocol is used by browser applications to communicate with web servers.
When the user enters a URL, the browser generates a GET request.
For simplicity, this program will only simulate GET and POST requests

Default port : 443

Each HTTP request must contain 3 elements:
  1. The method - GET, POST, etc...
  2. The request target - /google.com       *Must begin with forward slash '/', if the request is a root request(homepage) a single '/' is all that is necessary.
  3. The HTTP version - HTTP/1.1

Example GET request
   ‘GET /sometopic.html HTTP/1.1’

Example POST request
  'POST /resource/path HTTP/1.1'

=end

require_relative 'Protocol'

class HTTPSProtocolHandler
  include Protocol

  # The overall form of the protocol regex
  PROTOCOL_REGEX = /\A(?<method>[A-Z]+)\s+(?<target>\S+)\s+(?<version>HTTP\/\d\.\d)\z/

  URL_REGEX = %r{\A/https?://[^\s/$.?#].[^\s]*\z}i     # The target/path section of the protocol format
  VERSION_REGEX = %r{\AHTTP\/\d\.\d}                  # The version section of the protocol format

  def initialize
    super(PROTOCOL_REGEX)
    add_regex_group(:method)
    add_to_group(:method, :GET, "GET")
    add_to_group(:method, :POST, "POST")
    add_regex_group(:target)
    add_to_group(:target, :URL, URL_REGEX)
    add_regex_group(:version)
    add_to_group(:version, :ANY, VERSION_REGEX)
  end

end