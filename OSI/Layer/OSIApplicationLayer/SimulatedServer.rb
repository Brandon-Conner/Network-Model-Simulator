require_relative 'PacketBuilder'
require_relative 'PacketScenarios'
require_relative 'TLSPacketBuilder'

# Simulated server that generates network packets for the assignment.
#
# Receives requests from SimulatedClient and generates all required packet
# scenarios: SYN, ACK, HTTP GET, ACK packets, and FIN-ACK.
# Supports TLS simulation with configurable cipher suites.
class SimulatedServer

	attr_reader :cipher_suites

	DEFAULT_CIPHER_SUITES = [
		0x002F 
	].freeze

	def initialize(client_port, server_port, cipher_suites: nil)
		@source_ip = "192.168.1.100"  # Client IP
		@destination_ip = "172.66.128.35"  # Server IP (tulsa.okstate.edu)
		@source_port = client_port  
		@destination_port = server_port
		@source_mac = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55]
		@destination_mac = [0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E]
		@cipher_suites = cipher_suites || DEFAULT_CIPHER_SUITES.dup
		@scenarios = PacketScenarios.new(
			@source_ip,
			@destination_ip,
			@source_port,
			@destination_port,
			@source_mac,
			@destination_mac
		)
		@tls_builder = TLSPacketBuilder.new
	end
	

	def generate_all_packets(client_cipher_suites: nil)
		packets = []
		client_suites = client_cipher_suites || @cipher_suites
		negotiated = @cipher_suites.find { |cs| client_suites.include?(cs) } || @cipher_suites.first
		packets << @scenarios.generate_syn_packet(:client)						# Scenario 1: SYN (client → server)
		packets << @scenarios.generate_ack_packet(:client)						# Scenario 2: ACK (client → server)
		client_hello_payload = @tls_builder.client_hello("tulsa.okstate.edu", client_suites)		# Scenario 3: TLS Client Hello (client → server)
		packets << @scenarios.generate_packet_with_direction(:client,
			payload: client_hello_payload,
			flags:   PacketBuilder::TCP_FLAG_PSH_ACK,
			seq:     @scenarios.client_seq + 1,
			ack:     @scenarios.server_seq + 1
		)
		server_hello_payload = @tls_builder.server_hello(negotiated)			# Scenario 4: TLS Server Hello (server → client)
		packets << @scenarios.generate_packet_with_direction(:server,
			payload: server_hello_payload,
			flags:   PacketBuilder::TCP_FLAG_PSH_ACK,
			seq:     @scenarios.server_seq + 1,
			ack:     @scenarios.client_seq + 1 + client_hello_payload.bytesize
		)
		packets << @scenarios.generate_ack_packet(:client)						# Scenario 5: ACK for Server Hello
		http_payload = PacketBuilder.new.build_http_request(							# Scenario 6: HTTP GET over TLS
		"/undergraduate-academics/computerscience.html",
			"tulsa.okstate.edu"
		)
		packets << @scenarios.generate_packet_with_direction(:client,
			payload: @tls_builder.encrypt_request(http_payload),
			flags:   PacketBuilder::TCP_FLAG_PSH_ACK,
			seq:     @scenarios.client_seq + 1 + client_hello_payload.bytesize,
			ack:     @scenarios.server_seq + 1
		)
		packets.concat(@scenarios.generate_ack_packets_for_server_data)		# Scenario 7: ACKs for server data
		packets << @scenarios.generate_fin_ack_packet											# Scenario 8: FIN-ACK
		packets
	end
	

	def handle_request(request, **options)
		case request
		when "generate_packets"
			generate_all_packets(client_cipher_suites: options[:cipher_suites])
		else
			raise ArgumentError, "Unknown request: #{request}"
		end
	end
end # End of SimulatedServer.rb