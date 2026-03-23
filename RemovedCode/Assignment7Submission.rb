# Assignment 7 Firewall
require 'openssl'

# Builds Ethernet, IP, TCP headers and HTTP payloads for packet simulation.
class PacketBuilder
  ETHER_TYPE_IPv4 = 0x0800
  TCP_FLAG_FIN = 0x01
  TCP_FLAG_SYN = 0x02
  TCP_FLAG_RST = 0x04
  TCP_FLAG_PSH = 0x08
  TCP_FLAG_ACK = 0x10
  TCP_FLAG_URG = 0x20
  TCP_FLAG_SYN_ACK = TCP_FLAG_SYN | TCP_FLAG_ACK
  TCP_FLAG_PSH_ACK = TCP_FLAG_PSH | TCP_FLAG_ACK
  TCP_FLAG_FIN_ACK = TCP_FLAG_FIN | TCP_FLAG_ACK

  def build_ethernet_frame_header(dest_mac, src_mac)
    [*dest_mac, *src_mac, ETHER_TYPE_IPv4].pack('C6C6n')
  end

  def build_ip_header(src_ip, dst_ip, total_len, protocol = 6, ttl = 64)
    vihl = (4 << 4) | 5
    [vihl, 0, total_len, 0x1234, 0x4000, ttl, protocol, 0, ip_to_int(src_ip), ip_to_int(dst_ip)].pack('CCn n n CCn N N')
  end

  def build_tcp_header(src_port, dst_port, seq, ack, flags, win = 8192)
    dof = (5 << 12) | flags
    [src_port, dst_port, seq, ack, dof, win, 0, 0].pack('nn N N n n n n')
  end

  def build_http_request(path, host, extra = {})
    r = "GET #{path} HTTP/1.1\r\nHost: #{host}\r\n"
    extra.each { |k, v| r << "#{k}: #{v}\r\n" }
    r << "\r\n"
  end

  def build_complete_packet(eth, ip, tcp, payload = "")
    raise ArgumentError unless eth.bytesize == 14 && ip.bytesize == 20 && tcp.bytesize == 20
    eth + ip + tcp + payload
  end

  private
  def ip_to_int(ip) ip.split('.').map(&:to_i).pack('C4').unpack('N').first end
end

# Generates packet scenarios (SYN, ACK, HTTP, TLS, FIN) for client or server direction.
class PacketScenarios
  attr_reader :client_seq, :server_seq

  def initialize(client_ip, server_ip, client_port, server_port, client_mac, server_mac)
    @builder = PacketBuilder.new
    @client_ip, @server_ip = client_ip, server_ip
    @client_port, @server_port = client_port, server_port
    @client_mac, @server_mac = client_mac, server_mac
    @client_seq, @server_seq = 0x12345678, 0x87654321
  end

  def addresses_for_direction(dir)
    dir == :client ? {source_ip:@client_ip, destination_ip:@server_ip, source_port:@client_port, destination_port:@server_port, source_mac:@client_mac, destination_mac:@server_mac} :
      {source_ip:@server_ip, destination_ip:@client_ip, source_port:@server_port, destination_port:@client_port, source_mac:@server_mac, destination_mac:@client_mac}
  end

  def generate_packet_with_direction(dir, payload: "", flags:, seq:, ack:)
    addr = addresses_for_direction(dir)
    eth = @builder.build_ethernet_frame_header(addr[:destination_mac], addr[:source_mac])
    ip = @builder.build_ip_header(addr[:source_ip], addr[:destination_ip], 40 + payload.bytesize)
    tcp = @builder.build_tcp_header(addr[:source_port], addr[:destination_port], seq, ack, flags)
    @builder.build_complete_packet(eth, ip, tcp, payload)
  end

  def generate_syn_packet(dir = :client)
    generate_packet_with_direction(dir, flags: PacketBuilder::TCP_FLAG_SYN, seq: @client_seq, ack: 0)
  end

  def generate_ack_packet(dir = :client, seq: nil, ack: nil)
    seq ||= dir == :client ? @client_seq + 1 : @server_seq + 1
    ack ||= dir == :client ? @server_seq + 1 : @client_seq + 1
    generate_packet_with_direction(dir, flags: PacketBuilder::TCP_FLAG_ACK, seq: seq, ack: ack)
  end

  def generate_ack_packets_for_server_data(sz = 1460, dir = :client)
    ack_packets = []
    acknowledged = 0
    [4, 3, 3].each do |n|
      acknowledged += n * sz
      ack_packets << generate_ack_packet(dir, seq: @client_seq + 1, ack: @server_seq + 1 + acknowledged)
    end
    ack_packets
  end

  def generate_fin_ack_packet(dir = :client)
    generate_packet_with_direction(dir, flags: PacketBuilder::TCP_FLAG_FIN_ACK, seq: @client_seq + 1 + 80, ack: @server_seq + 1 + (10 * 1460))
  end
end

# Formats packets as hex, readable (IP/TCP + payload), or char-printing.
class PacketFormatters
  def format_hex(packets)
    packets.each_with_index.map { |p, i| "Packet #{i+1}:\n#{format_hex_single(p)}" }.join("\n\n")
  end

  def format_readable(packets)
    packets.each_with_index.map do |p, i|
      ip_tcp = p.byteslice(14..-1)
      ip = ip_tcp.byteslice(0, 20)
      tcp = ip_tcp.byteslice(20, 20)
      payload = ip_tcp.byteslice(40..-1)
      "="*80 + "\nPacket #{i+1}:\n" + "="*80 + "\n\nIP Header (20 bytes):\n" + format_ip(ip) + "\n\nTCP Header (20 bytes):\n" + format_tcp(tcp) + "\n\nPayload (#{payload&.bytesize||0} bytes):\n#{payload||'(empty)'}\n"
    end.join("\n")
  end

  def format_char_printing(packets)
    packets.each_with_index.map do |p, i|
      h = p.byteslice(0, 54)
      pl = p.byteslice(54..-1)
      "Packet #{i+1}:\nHeaders (as characters):\n#{format_chars(h)}" + (pl && pl.bytesize > 0 ? "\nPayload:\n#{pl}" : "") + "\n"
    end.join("\n")
  end

  private
  def format_hex_single(p)
    p.bytes.each_slice(16).map { |c| c.map { |b| "%02X" % b }.join(' ') }.join("\n")
  end

  def format_ip(b)
    v, ihl = (b.getbyte(0) >> 4) & 0x0F, b.getbyte(0) & 0x0F
    tl = (b.getbyte(2) << 8) | b.getbyte(3)
    prot = b.getbyte(9)
    prot_n = {1=>"ICMP", 6=>"TCP", 17=>"UDP"}[prot] || "Unknown(#{prot})"
    "  Version: #{v}  IHL: #{ihl}  Total Length: #{tl}  Protocol: #{prot} (#{prot_n})"
  end

  def format_tcp(b)
    sp = (b.getbyte(0) << 8) | b.getbyte(1)
    dp = (b.getbyte(2) << 8) | b.getbyte(3)
    seq = (b.getbyte(4) << 24) | (b.getbyte(5) << 16) | (b.getbyte(6) << 8) | b.getbyte(7)
    ack = (b.getbyte(8) << 24) | (b.getbyte(9) << 16) | (b.getbyte(10) << 8) | b.getbyte(11)
    "  Source Port: #{sp}  Dest Port: #{dp}  Seq: #{seq}  Ack: #{ack}"
  end

  def format_chars(d)
    d.each_byte.map { |b| (b >= 0x20 && b <= 0x7E) ? b.chr : (b < 0x20 ? "" : b.chr) }.join
  end
end

# Builds TLS handshake and application data records for HTTPS simulation.
class TLSPacketBuilder
  RECORD_HANDSHAKE, RECORD_APPLICATION, RECORD_CHANGE_CIPHER = 0x16, 0x17, 0x14
  TLS_VER = [0x03, 0x03]
  HANDSHAKE_CH, HANDSHAKE_SH, HANDSHAKE_CKE, HANDSHAKE_FIN = 0x01, 0x02, 0x10, 0x14
  AES_KEY = "0123456789abcdef".b
  AES_IV = "fedcba9876543210".b

  def wrap_message_in_tls_record(ct, payload)
    len = payload.bytesize
    [ct, *TLS_VER, (len >> 8) & 0xFF, len & 0xFF].pack('CCCCC') + payload
  end

  def client_hello(host = "tulsa.okstate.edu", ciphers = [0x002F])
    cs_bytes = ciphers.map { |c| [(c >> 8) & 0xFF, c & 0xFF].pack('CC') }.join
    rnd = (0...32).map { rand(256) }.pack('C*')
    body = [0x03, 0x03].pack('CC') + rnd + 0.chr + "" + [cs_bytes.bytesize].pack('n') + cs_bytes + 1.chr + 0.chr + build_sni(host)
    wrap_message_in_tls_record(RECORD_HANDSHAKE, HANDSHAKE_CH.chr + [body.bytesize].pack('N')[1, 3] + body)
  end

  def server_hello(cipher = 0x002F)
    cs = [(cipher >> 8) & 0xFF, cipher & 0xFF].pack('CC')
    rnd = (0...32).map { rand(256) }.pack('C*')
    body = [0x03, 0x03].pack('CC') + rnd + 0.chr + "" + cs + 0.chr + [0, 0].pack('n')
    wrap_message_in_tls_record(RECORD_HANDSHAKE, HANDSHAKE_SH.chr + [body.bytesize].pack('N')[1, 3] + body)
  end

  def encrypt_request(plaintext)
    c = OpenSSL::Cipher.new('AES-128-CBC')
    c.encrypt
    c.key, c.iv = AES_KEY, AES_IV
    wrap_message_in_tls_record(RECORD_APPLICATION, c.update(plaintext) + c.final)
  end

  def decrypt_request(record)
    return "".b if record.bytesize < 5
    c = OpenSSL::Cipher.new('AES-128-CBC')
    c.decrypt
    c.key, c.iv = AES_KEY, AES_IV
    c.update(record.byteslice(5..-1)) + c.final
  rescue OpenSSL::Cipher::CipherError
    "".b
  end

  private
  def build_sni(host)
    sd = 0.chr + [host.bytesize].pack('n') + host
    [0, 0].pack('n') + [sd.bytesize].pack('n') + sd
  end
end

# Simulated server that generates SYN, ACK, TLS, HTTP, and FIN packets.
class SimulatedServer
  DEFAULT_CIPHER_SUITES = [0x002F].freeze

  def initialize(client_port, server_port, cipher_suites: nil)
    @cipher_suites = cipher_suites || DEFAULT_CIPHER_SUITES.dup
    @scenarios = PacketScenarios.new("192.168.1.100", "172.66.128.35", client_port, server_port,
      [0x00, 0x11, 0x22, 0x33, 0x44, 0x55], [0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E])
    @tls = TLSPacketBuilder.new
  end

  def generate_all_packets(client_cipher_suites: nil)
    cs = client_cipher_suites || @cipher_suites
    neg = @cipher_suites.find { |c| cs.include?(c) } || @cipher_suites.first
    ch = @tls.client_hello("tulsa.okstate.edu", cs)
    sh = @tls.server_hello(neg)
    http = PacketBuilder.new.build_http_request("/undergraduate-academics/computerscience.html", "tulsa.okstate.edu")
    [
      @scenarios.generate_syn_packet(:client),
      @scenarios.generate_ack_packet(:client),
      @scenarios.generate_packet_with_direction(:client, payload: ch, flags: PacketBuilder::TCP_FLAG_PSH_ACK, seq: @scenarios.client_seq + 1, ack: @scenarios.server_seq + 1),
      @scenarios.generate_packet_with_direction(:server, payload: sh, flags: PacketBuilder::TCP_FLAG_PSH_ACK, seq: @scenarios.server_seq + 1, ack: @scenarios.client_seq + 1 + ch.bytesize),
      @scenarios.generate_ack_packet(:client),
      @scenarios.generate_packet_with_direction(:client, payload: @tls.encrypt_request(http), flags: PacketBuilder::TCP_FLAG_PSH_ACK, seq: @scenarios.client_seq + 1 + ch.bytesize, ack: @scenarios.server_seq + 1),
      *@scenarios.generate_ack_packets_for_server_data,
      @scenarios.generate_fin_ack_packet
    ]
  end

  def handle_request(req, **opts)
    req == "generate_packets" ? generate_all_packets(client_cipher_suites: opts[:cipher_suites]) : raise(ArgumentError, "Unknown: #{req}")
  end
  attr_reader :cipher_suites
end

# Filters packets by accesslist (ports) and denylist (IPs); auto-forwards outgoing.
class Firewall
  ETHERNET_HEADER_SIZE = 14
  IP_HEADER_SIZE = 20
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
    return true if source_ip == @client_ip
    return false if @denylist.include?(source_ip)
    source_port = extract_source_port(packet)
    return false unless @accesslist.include?(source_port)
    true
  end

  def filter_packets(packets)
    packets.select { |p| allow_packet?(p) }
  end

  private
  def extract_source_ip(packet)
    ip_header = packet.byteslice(ETHERNET_HEADER_SIZE, IP_HEADER_SIZE)
    return nil if ip_header.nil? || ip_header.bytesize < 16
    ip_header.byteslice(IP_SOURCE_ADDRESS_OFFSET, 4).bytes.join('.')
  end

  def extract_source_port(packet)
    tcp_header = packet.byteslice(ETHERNET_HEADER_SIZE + IP_HEADER_SIZE, 20)
    return 0 if tcp_header.nil? || tcp_header.bytesize < 2
    high, low = tcp_header.byteslice(0, 2).bytes
    (high << 8) | low
  end
end

# Client UI: requests packets from server, filters via firewall, displays in chosen format.
class SimulatedClient
  DEFAULT_CIPHER_SUITES = [0x002F].freeze

  def initialize(server, firewall, cipher_suites: nil)
    @server = server
    @firewall = firewall
    @formatter = PacketFormatters.new
    @packets = nil
    @cipher_suites = cipher_suites || DEFAULT_CIPHER_SUITES.dup
  end

  def run
    puts "=" * 80
    puts "Network Packet Simulation"
    puts "=" * 80
    puts "\nCipher suites: #{@cipher_suites.map { |c| "0x%04X" % c }.join(', ')}"
    puts "\nRequesting packets from simulated server..."
    raw_packets = @server.handle_request("generate_packets", cipher_suites: @cipher_suites)
    @packets = @firewall.filter_packets(raw_packets)
    puts "Received #{@packets.length} packets from server.\n"
    display_menu
    choice = get_user_choice
    format_and_display(choice)
  end

  def display_menu
    puts "=" * 80
    puts "Select Output Format:"
    puts "1. Print the Hex Codes of all sent packets (01 23 45 67 89 AB CD EF format)"
    puts "2. Print payload as text, skip Ethernet, IP/TCP headers as binary with interpretation"
    puts "3. Headers as pure char printing"
    puts "Enter your choice (1, 2, or 3): "
  end

  def get_user_choice
    choice = gets.chomp.strip
    return get_user_choice unless ['1', '2', '3'].include?(choice)
    choice.to_i
  end

  def format_and_display(choice)
    puts "\n" + "=" * 80 + "\nFormatted Output:\n" + "=" * 80 + "\n"
    output = case choice
      when 1 then @formatter.format_hex(@packets)
      when 2 then @formatter.format_readable(@packets)
      when 3 then @formatter.format_char_printing(@packets)
      else "Invalid choice!"
    end
    puts output
    puts "\n" + "=" * 80
  end
  attr_reader :cipher_suites
end