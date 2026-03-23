
require_relative 'PacketBuilder'


class Firewall

  ETHERNET_HEADER_SIZE = 14
  IP_HEADER_SIZE = 20
  TCP_HEADER_SIZE = 20


  IP_SOURCE_ADDRESS_OFFSET = 12
  TCP_SOURCE_PORT_OFFSET = 0


  DEFAULT_SERVER_IP = "172.66.128.35"
  DEFAULT_CLIENT_IP = "192.168.1.100"


  attr_reader :accesslist, :denylist


  def initialize(accesslist: [443, 80], denylist: [], server_ip: DEFAULT_SERVER_IP, client_ip: DEFAULT_CLIENT_IP)
    @accesslist = accesslist.freeze
    @denylist = denylist.freeze
    @server_ip = server_ip
    @client_ip = client_ip
  end



  def allow_packet?(packet)
    return false if packet.bytesize < 54
    source_ip = extract_source_ip(packet)
    return false if source_ip.nil?
    return true if source_ip == @client_ip # Outgoing - auto forward
    return false if @denylist.include?(source_ip) # - check if IP is blocked
    source_port = extract_source_port(packet)
    return false unless @accesslist.include?(source_port)
    true
  end



  # Filter packets, return only those that pass the firewall.
  def filter_packets(packets)
    packets.select { |p| allow_packet?(p) }
  end

  private

  def extract_source_ip(packet)
    ip_start = ETHERNET_HEADER_SIZE
    ip_header = packet.byteslice(ip_start, IP_HEADER_SIZE)
    return nil if ip_header.nil? || ip_header.bytesize < 16
    source_ip_bytes = ip_header.byteslice(IP_SOURCE_ADDRESS_OFFSET, 4)
    source_ip_bytes.bytes.join('.')
  end



  def extract_source_port(packet)
    tcp_start = ETHERNET_HEADER_SIZE + IP_HEADER_SIZE
    tcp_header = packet.byteslice(tcp_start, TCP_HEADER_SIZE)
    return 0 if tcp_header.nil? || tcp_header.bytesize < 2
    source_port_bytes = tcp_header.byteslice(TCP_SOURCE_PORT_OFFSET, 2)
    high_byte, low_byte = source_port_bytes.bytes
    (high_byte << 8) | low_byte
  end

end # End of Firewall.rb