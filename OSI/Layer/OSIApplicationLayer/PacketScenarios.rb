require_relative 'PacketBuilder'

# Generates all packet scenarios required for the assignment.
#
# Supports bidirectional packet generation via a direction flag (:client or :server).
# :client = packet from client to server (source=client, dest=server)
# :server = packet from server to client (source=server, dest=client)
#
class PacketScenarios

	# Direction constants for packet generation
	DIRECTION_CLIENT = :client   # Client → Server
	DIRECTION_SERVER = :server   # Server → Client

	attr_reader :client_seq, :server_seq

	def initialize(client_ip, server_ip, client_port, server_port, client_mac, server_mac)
		@builder = PacketBuilder.new
		# Store client and server addresses separately for direction-based swapping
		@client_ip = client_ip
		@server_ip = server_ip
		@client_port = client_port
		@server_port = server_port
		@client_mac = client_mac
		@server_mac = server_mac
		# TCP sequence numbers (simulated)
		@client_seq = 0x12345678
		@server_seq = 0x87654321
	end
	
	# Returns address components for the given direction.
	# @param direction [Symbol] :client or :server
	# @return [Hash] { source_ip:, destination_ip:, source_port:, destination_port:, source_mac:, destination_mac: }
	def addresses_for_direction(direction)
		case direction
		when :client, DIRECTION_CLIENT
			{
				source_ip:        @client_ip,
				destination_ip:   @server_ip,
				source_port:      @client_port,
				destination_port: @server_port,
				source_mac:       @client_mac,
				destination_mac:  @server_mac
			}
		when :server, DIRECTION_SERVER
			{
				source_ip:        @server_ip,
				destination_ip:   @client_ip,
				source_port:      @server_port,
				destination_port: @client_port,
				source_mac:       @server_mac,
				destination_mac:  @client_mac
			}
		else
			raise ArgumentError, "Invalid direction: #{direction}. Use :client or :server."
		end
	end
	
	# Builds Ethernet header for the given direction.
	# @param direction [Symbol] :client or :server
	# @return [String] 14-byte Ethernet header
	def ethernet_header_for_direction(direction)
		addr = addresses_for_direction(direction)
		@builder.build_ethernet_frame_header(addr[:destination_mac], addr[:source_mac])
	end
	
	# Generates a packet with the given payload and TCP flags.
	# @param direction [Symbol] :client or :server
	# @param payload [String] TCP payload (default "")
	# @param flags [Integer] TCP flags (e.g., PacketBuilder::TCP_FLAG_SYN)
	# @param seq [Integer] Sequence number
	# @param ack [Integer] Acknowledgment number
	# @return [String] Complete packet
	def generate_packet_with_direction(direction, payload: "", flags:, seq:, ack:)
		addr = addresses_for_direction(direction)
		ethernet = ethernet_header_for_direction(direction)
		payload_size = payload.bytesize
		total_length = 20 + 20 + payload_size
		ip_header = @builder.build_ip_header(addr[:source_ip], addr[:destination_ip], total_length)
		tcp_header = @builder.build_tcp_header(
			addr[:source_port],
			addr[:destination_port],
			seq,
			ack,
			flags
		)
		@builder.build_complete_packet(ethernet, ip_header, tcp_header, payload)
	end
	

	def generate_syn_packet(direction = :client)
		generate_packet_with_direction(direction,
			flags: PacketBuilder::TCP_FLAG_SYN,
			seq:   @client_seq,
			ack:   0
		)
	end
	

	def generate_ack_packet(direction = :client, seq: nil, ack: nil)
		seq ||= (direction == :client) ? @client_seq + 1 : @server_seq + 1
		ack ||= (direction == :client) ? @server_seq + 1 : @client_seq + 1
		generate_packet_with_direction(direction,
			flags: PacketBuilder::TCP_FLAG_ACK,
			seq:   seq,
			ack:   ack
		)
	end
	

	def generate_http_request_packet(path = "/undergraduate-academics/computerscience.html", host = "tulsa.okstate.edu", direction = :client)
		http_payload = @builder.build_http_request(path, host)
		generate_packet_with_direction(direction,
			payload: http_payload,
			flags:   PacketBuilder::TCP_FLAG_PSH_ACK,
			seq:     @client_seq + 1,
			ack:     @server_seq + 1
		)
	end
	

	def generate_ack_packets_for_server_data(server_packet_size = 1460, direction = :client)
		ack_packets = []
		acknowledged_bytes = 0
		[4, 3, 3].each do |packets_to_ack|
			acknowledged_bytes += packets_to_ack * server_packet_size
			ack_packets << generate_ack_packet(direction,
				seq: @client_seq + 1,
				ack: @server_seq + 1 + acknowledged_bytes
			)
		end
		ack_packets
	end
	

	def generate_fin_ack_packet(direction = :client)
		generate_packet_with_direction(direction,
			flags: PacketBuilder::TCP_FLAG_FIN_ACK,
			seq:   @client_seq + 1 + 80,
			ack:   @server_seq + 1 + (10 * 1460)
		)
	end
end