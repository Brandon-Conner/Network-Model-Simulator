
class PacketBuilder

	# Protocols
	ETHER_TYPE_IPv4 = 0x0800 # Standard protocol
	ETHER_TYPE_ARP  = 0x0806
	ETHER_TYPE_IPv6 = 0x86DD

	# TCP Flags
	TCP_FLAG_FIN = 0x01  # Finish
	TCP_FLAG_SYN = 0x02  # Synchronize
	TCP_FLAG_RST = 0x04  # Reset
	TCP_FLAG_PSH = 0x08  # Push
	TCP_FLAG_ACK = 0x10  # Acknowledgment
	TCP_FLAG_URG = 0x20  # Urgent

	# Common flag combinations
	TCP_FLAG_SYN_ACK = TCP_FLAG_SYN | TCP_FLAG_ACK  # 0x12
	TCP_FLAG_PSH_ACK = TCP_FLAG_PSH | TCP_FLAG_ACK  # 0x18
	TCP_FLAG_FIN_ACK = TCP_FLAG_FIN | TCP_FLAG_ACK  # 0x11

	# Builds a standard Ethernet frame header (Layer 2) for network packet simulation.
	# Constructs the 14-byte Ethernet header that encapsulates IP packets at the data
	# link layer. The header identifies source/destination MAC addresses and the protocol
	# type of the encapsulated payload.
	# @param destination_mac_address [Array<Integer>] Array of 6 bytes (0x00-0xFF) representing
	#   the destination MAC address. Example: [0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E]
	# @param source_mac_address [Array<Integer>] Array of 6 bytes (0x00-0xFF) representing
	#   the source MAC address. Example: [0x11, 0x22, 0x33, 0x44, 0x55, 0x66]
	def build_ethernet_frame_header(destination_mac_address, source_mac_address)
		[*destination_mac_address, *source_mac_address, ETHER_TYPE_IPv4].pack('C6C6n')
	end


	# Builds a standard IPv4 header (Layer 3) for network packet simulation.
	# Constructs the 20-byte IPv4 header that encapsulates TCP segments at the network
	# layer. The IP header provides routing information, packet identification,
	# fragmentation control, and protocol identification.
	# @param source_ip_address [String] IPv4 address in dotted-decimal notation.          			
	# @param destination_ip_address [String] IPv4 address in dotted-decimal notation.				
	# @param total_length [Integer] Total packet length in bytes(IP header + TCP header + payload). Must be at least 20 (IP header size).														
	# @param protocol [Integer] Protocol number: 6 = TCP, 1 = ICMP, 17 = UDP.						
	# @param ttl [Integer] Time To Live (maximum hops before packet is discarded).
	# @return [String] 20-byte binary string containing:
	def build_ip_header(source_ip_address, destination_ip_address, total_length, protocol = 6, ttl = 64)
		version_ihl = (4 << 4) | 5   				# Version 4, IHL 5 (20 bytes) = 0x45
		tos = 0           									# Type of Service
		id = 0x1234   											# Identification
		flags_frag = 0x4000 								# Flags: Don't Fragment
		checksum = 0												# Header checksum (0 for simulation)
		source_ip_int = ip_to_int(source_ip_address) 		# Convert IP addresses from strings to 32-bit integers
		destination_ip_int = ip_to_int(destination_ip_address)
		# Pack: C=char, n=16-bit network byte order, N=32-bit network byte order
		[version_ihl, tos, total_length, id, flags_frag, ttl, protocol, checksum, source_ip_int, destination_ip_int].pack('CCn n n CCn N N')
	end


	# Converts an IPv4 address string to a 32-bit integer in network byte order.
	# @param ip_string [String] IPv4 address in dotted-decimal notation.
	#   Example: "192.168.1.100"
	# @return [Integer] 32-bit integer representation of the IP address in network byte order.
	#   Example: "192.168.1.100" => 3232235876 (0xC0A80164)
	private
	def ip_to_int(ip_string)
		# Split IP string into octets, convert to integers, pack as 4 bytes, unpack as 32-bit integer
		ip_string.split('.').map(&:to_i).pack('C4').unpack('N').first
	end

	public

	# Builds a standard TCP header (Layer 4) for network packet simulation.
	# Constructs the 20-byte TCP header that encapsulates application layer data (like HTTP) at the transport layer.
	# The TCP header provides connection management, reliable delivery, flow control, and port identification.
	# @param source_port [Integer] Source port number (0-65535). 										Ephemeral ports typically: 49152-65535.
	# @param destination_port [Integer] Destination port number (0-65535).          Common: 80 (HTTP), 443 (HTTPS).
	# @param sequence_number [Integer] 32-bit sequence number tracking bytes sent.  Increments by payload size for each packet.
	# @param acknowledgment_number [Integer] 32-bit acknowledgment number (next exp. seq.).
	#   Valid only if ACK flag is set.     SYN packet: 0 (no acknowledgment).      	After SYN-ACK: server_seq + 1.
	# @param flags [Integer] TCP flags as bitmask (9 bits).
	# @param window_size [Integer] Receive window size in bytes (16-bit).   				Default: 8192 (0x2000).   Maximum: 65535 (0xFFFF).
	# @return [String] 20-byte binary string containing:
	def build_tcp_header(source_port, destination_port, sequence_number, acknowledgment_number, flags, window_size = 8192)
		data_offset_flags = (5 << 12) | flags							# Data Offset = 5 (20 bytes) in upper 4 bits, flags in lower 12 bits
		checksum = 0																			# Checksum (0 for simulation)
		urgent_pointer = 0																# Urgent Pointer (0 unless URG flag is set)
		# Pack: n=16-bit network byte order, N=32-bit network byte order
		[source_port, destination_port, sequence_number, acknowledgment_number, data_offset_flags, window_size, checksum, urgent_pointer].pack('nn N N n n n n')
	end


	# Builds an HTTP GET request string for use as TCP payload. Constructs a properly formatted HTTP/1.1 GET request that can be used as the
	# payload in a TCP packet. The request follows standard HTTP protocol format with request line, Host header, and proper line endings.
	# @param path [String] The path portion of the URL (without domain). 					Should start with '/' for absolute path.
	# @param host [String] The hostname or domain name for the Host header.
	# @param additional_headers [Hash] Optional additional HTTP headers as key-value pairs. 	Default: {} (no additional headers)
	# @return [String] Complete HTTP GET request string with:
	def build_http_request(path, host, additional_headers = {})
		request = "GET #{path} HTTP/1.1\r\n" ;								request << "Host: #{host}\r\n"
		additional_headers.each do |key, value|; 			request << "#{key}: #{value}\r\n"; end   		# Add any additional headers
		request << "\r\n";																		request   																	# Empty line signals end of headers
	end


	# Assembles a complete network packet from individual header components and payload. Combines Ethernet header, IP header,
	# TCP header, and optional payload into a single binary packet ready for transmission simulation. The packet structure
	# follows the standard network stack layering: Ethernet (Layer 2) encapsulates IP (Layer 3), which encapsulates TCP (Layer 4),
	# which encapsulates the application payload (Layer 7).
	# @param ethernet_header [String] Binary string containing the 14-byte Ethernet header. 	Should be created using {#build_ethernet_frame_header}.
	# @param ip_header [String] Binary string containing the 20-byte IPv4 header. 						Should be created using {#build_ip_header}.
	# @param tcp_header [String] Binary string containing the 20-byte TCP header. 						Should be created using {#build_tcp_header}.
	# @param payload [String] Optional application layer payload (e.g., HTTP request). 				Can be empty string for packets without payload (e.g., SYN, ACK packets).
	#   Default: "" (empty string).
	# @return [String] Complete binary packet string containing:
	#   - Ethernet header (14 bytes)
	#   - IP header (20 bytes)
	#   - TCP header (20 bytes)
	#   - Payload (variable length, 0+ bytes)
	#   Total length: 54 bytes minimum (with empty payload)
	def build_complete_packet(ethernet_header, ip_header, tcp_header, payload = "") 		# Optional validation (can be removed for simplicity)
		raise ArgumentError, "Ethernet header must be 14 bytes" unless ethernet_header.bytesize == 14
		raise ArgumentError, "IP header must be 20 bytes" unless ip_header.bytesize == 20
		raise ArgumentError, "TCP header must be 20 bytes" unless tcp_header.bytesize == 20
		ethernet_header + ip_header + tcp_header + payload   		# Concatenate all components in order: Ethernet -> IP -> TCP -> Payload
	end


end # End of PacketBuilder.rb