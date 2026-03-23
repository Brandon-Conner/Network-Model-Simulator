# Formats network packets in different output styles
#
# Provides three formatting methods:
# 1. Hex codes format: Space-separated hex bytes in "01 23 45 67..." format
# 2. Readable format: Payload as text, headers with binary and interpretation
# 3. Char printing format: Headers printed as raw characters
class PacketFormatters
	
	# Formats packets as hex codes (Option 1).
	# Displays all sent packets in hex format with 16 bytes per line,
	# space-separated: "01 23 45 67 89 AB CD EF\n"
	# @param packets [Array<String>] Array of binary packet strings.
	# @return [String] Formatted hex dump of all packets.
	# @example
	#   formatter = PacketFormatters.new
	#   hex_output = formatter.format_hex([packet1, packet2])
	#   # => "Packet 1:\n00 1A 2B 3C 4D 5E 11 22 33 44 55 66 08 00 45 00\n..."
	def format_hex(packets)
		output = []
		packets.each_with_index do |packet, index|
			output << "Packet #{index + 1}:"
			output << format_single_packet_hex(packet)
			output << ""  																	# Empty line between packets
		end
		output.join("\n")
	end


	# Formats packets in readable format (Option 2).
	# Displays payload as text, skips Ethernet header, and prints TCP and IP headers
	# as binary with each field on a new line.
	# @param packets [Array<String>] Array of binary packet strings.
	# @return [String] readable formatted output.
	# @example
	#   formatter = PacketFormatters.new
	#   readable_output = formatter.format_readable([packet1, packet2])
	def format_readable(packets)
		output = []
		packets.each_with_index do |packet, index|
			output << "=" * 80
			output << "Packet #{index + 1}:"
			output << "=" * 80
			ethernet_size = 14																		# Skip Ethernet header (first 14 bytes)
			ip_tcp_payload = packet.byteslice(ethernet_size..-1)
			ip_header = ip_tcp_payload.byteslice(0, 20)						# Parse and display IP header (20 bytes)
			output << "\nIP Header (20 bytes):"
			output << format_ip_header_readable(ip_header)
			tcp_header = ip_tcp_payload.byteslice(20, 20)					# Parse and display TCP header (20 bytes)
			output << "\nTCP Header (20 bytes):"
			output << format_tcp_header_readable(tcp_header)
			payload = ip_tcp_payload.byteslice(40..-1)						# Display payload as text
			if payload && payload.bytesize > 0
				output << "\nPayload (#{payload.bytesize} bytes):"
				output << payload
			else
				output << "\nPayload: (empty)"
			end
			output << "\n"
		end
		output.join("\n")
	end
	

	# Formats packets as strings (Option 3).
	# @param packets [Array<String>] Array of binary packet strings.
	# @return [String] Character-formatted output.
	def format_char_printing(packets)
		output = []
		packets.each_with_index do |packet, index|
			output << "Packet #{index + 1}:"							# Extract headers (Ethernet + IP + TCP = 54 bytes)
			headers = packet.byteslice(0, 54)
			payload = packet.byteslice(54..-1)
			output << "Headers (as characters):" 					# Print headers as characters
			output << format_bytes_as_chars(headers)
			if payload && payload.bytesize > 0						# Print payload if exists
				output << "\nPayload:"
				output << payload
			end
			output << "\n"
		end
		output.join("\n")
	end

	private
	

	# Formats a single packet as hex dump.
	# @param packet [String] Binary packet string.
	# @return [String] Hex-formatted packet.
	def format_single_packet_hex(packet)
		lines = []
		bytes = packet.bytes
		bytes.each_slice(16) do |chunk|
			hex_line = chunk.map { |b| sprintf("%02X", b) }.join(' ')
			lines << hex_line
		end
		lines.join("\n")
	end


	# Formats IP header in readable format.
	# @param ip_header [String] 20-byte IP header binary string.
	# @return [String] readable IP header.
	def format_ip_header_readable(ip_header)
		bytes = ip_header.bytes
		version_ihl = bytes[0]											# Byte 0: Version + IHL
		version = (version_ihl >> 4) & 0x0F
		ihl = version_ihl & 0x0F
		tos = bytes[1]															# Byte 1: TOS
		total_length = (bytes[2] << 8) | bytes[3]		# Bytes 2-3: Total Length
		id = (bytes[4] << 8) | bytes[5]							# Bytes 4-5: Identification
		flags_frag = (bytes[6] << 8) | bytes[7]			# Bytes 6-7: Flags + Fragment Offset
		flags = (flags_frag >> 13) & 0x07
		fragment_offset = flags_frag & 0x1FFF
		df_flag = (flags & 0x02) != 0
		mf_flag = (flags & 0x01) != 0
		ttl = bytes[8]										# Byte 8: TTL
		protocol = bytes[9]								# Byte 9: Protocol
		protocol_name = case protocol
			when 1 then "ICMP"
			when 6 then "TCP"
			when 17 then "UDP"
			else "Unknown (#{protocol})"
		end
		checksum = (bytes[10] << 8) | bytes[11]
		source_ip = "#{bytes[12]}.#{bytes[13]}.#{bytes[14]}.#{bytes[15]}"
		dest_ip = "#{bytes[16]}.#{bytes[17]}.#{bytes[18]}.#{bytes[19]}"
		output = []
		output << "  Binary: #{bytes.map { |b| sprintf("%08b", b) }.join(' ')}"
		output << "  Version: #{version} (IPv#{version})"
		output << "  IHL (Internet Header Length): #{ihl} (#{ihl * 4} bytes)"
		output << "  Type of Service: 0x#{sprintf("%02X", tos)}"
		output << "  Total Length: #{total_length} bytes"
		output << "  Identification: 0x#{sprintf("%04X", id)}"
		output << "  Flags: 0x#{sprintf("%01X", flags)} (DF=#{df_flag}, MF=#{mf_flag})"
		output << "  Fragment Offset: #{fragment_offset}"
		output << "  TTL: #{ttl}"
		output << "  Protocol: #{protocol} (#{protocol_name})"
		output << "  Header Checksum: 0x#{sprintf("%04X", checksum)}"
		output << "  Source IP Address: #{source_ip}"
		output << "  Destination IP Address: #{dest_ip}"
		output.join("\n")
	end
	

	# Formats TCP header in readable format.
	# @param tcp_header [String] 20-byte TCP header binary string.
	# @return [String] readable TCP header.
	def format_tcp_header_readable(tcp_header)
		bytes = tcp_header.bytes
		source_port = (bytes[0] << 8) | bytes[1]
		dest_port = (bytes[2] << 8) | bytes[3]
		seq_num = (bytes[4] << 24) | (bytes[5] << 16) | (bytes[6] << 8) | bytes[7]
		ack_num = (bytes[8] << 24) | (bytes[9] << 16) | (bytes[10] << 8) | bytes[11]
		data_offset_flags = (bytes[12] << 8) | bytes[13]
		data_offset = (data_offset_flags >> 12) & 0x0F
		reserved = (data_offset_flags >> 9) & 0x07
		flags = data_offset_flags & 0x1FF
		# Parse flags
		flag_names = []
		flag_names << "FIN" if (flags & 0x01) != 0
		flag_names << "SYN" if (flags & 0x02) != 0
		flag_names << "RST" if (flags & 0x04) != 0
		flag_names << "PSH" if (flags & 0x08) != 0
		flag_names << "ACK" if (flags & 0x10) != 0
		flag_names << "URG" if (flags & 0x20) != 0
		flags_str = flag_names.empty? ? "None" : flag_names.join(", ")
		window = (bytes[14] << 8) | bytes[15]
		checksum = (bytes[16] << 8) | bytes[17]
		urgent = (bytes[18] << 8) | bytes[19]
		output = []
		output << "  Binary: #{bytes.map { |b| sprintf("%08b", b) }.join(' ')}"
		output << "  Source Port: #{source_port}"
		output << "  Destination Port: #{dest_port}"
		output << "  Sequence Number: #{seq_num} (0x#{sprintf("%08X", seq_num)})"
		output << "  Acknowledgment Number: #{ack_num} (0x#{sprintf("%08X", ack_num)})"
		output << "  Data Offset: #{data_offset} (#{data_offset * 4} bytes)"
		output << "  Reserved: #{reserved}"
		output << "  Flags: 0x#{sprintf("%03X", flags)} (#{flags_str})"
		output << "  Window Size: #{window}"
		output << "  Checksum: 0x#{sprintf("%04X", checksum)}"
		output << "  Urgent Pointer: #{urgent}"
		output.join("\n")
	end
	

	# Formats bytes as characters (control characters print as nothing or space).
	# @param data [String] Binary data string.
	# @return [String] Character-formatted string.
	def format_bytes_as_chars(data)
		result = ""
		data.each_byte do |byte|
			if byte >= 0x20 && byte <= 0x7E # Printable ASCII
				result << byte.chr
			elsif byte < 0x20
				result << ""									# Control character - print nothing
			else
				result << byte.chr						# print as character
			end
		end
		result
	end
end