
require_relative 'PacketFormatters'
require_relative 'Firewall'
require_relative 'SimulatedServer'

# Simulated client that provides user interface and requests packets from server.
#
# Displays menu for selecting output format, sends requests to SimulatedServer,
# receives packets, and formats them for display.
class SimulatedClient

	DEFAULT_CIPHER_SUITES = [
		0x002F
	].freeze

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
		puts "Received #{@packets.length} packets from server."
		puts "\n"
		display_menu
		choice = get_user_choice
		format_and_display(choice)
	end
	

	def display_menu
		puts "=" * 80
		puts "Select Output Format:"
		puts "=" * 80
		puts "1. Print the Hex Codes of all sent packets"
		puts "    (nicely formatted in 01 23 45 67 89 AB CD EF\\n type format)"
		puts ""
		puts "2. Print the payload as text, skip the Ethernet header,"
		puts "    print the TCP and IP headers as binary with each field"
		puts "    on a new line, with a human-readable interpretation"
		puts ""
		puts "3. The headers as pure char printing"
		puts "    (i.e. if the hex value is B5, it'll print µ and if it's 0B,"
		puts "    it'll print nothing, as expected)"
		puts ""
		puts "Enter your choice (1, 2, or 3): "
	end


	def get_user_choice
		choice = gets.chomp.strip
		unless ['1', '2', '3'].include?(choice)
			puts "Invalid choice. Please enter 1, 2, or 3."
			return get_user_choice
		end
		choice.to_i
	end


	def format_and_display(choice)
		puts "\n" + "=" * 80
		puts "Formatted Output:"
		puts "=" * 80
		puts "\n"
		case choice
		when 1
			output = @formatter.format_hex(@packets)
		when 2
			output = @formatter.format_readable(@packets)
		when 3
			output = @formatter.format_char_printing(@packets)
		else
			puts "Invalid choice!"
			return
		end
		puts output
		puts "\n" + "=" * 80
	end
	attr_reader :cipher_suites
end


# Run the program if executed directly
if __FILE__ == $0
	begin
		run_simulation = false
		accepted_ports = []
		denied_ips = []
		while run_simulation != true
			puts "Enter client port: "
			client_port = gets.chomp.to_i
			puts "Enter server port (e.g. 443 for HTTPS): "
			server_port = gets.chomp.to_i
			accepted_ports << server_port
			puts "Firewall accesslist: " 
			for port in accepted_ports do 
				puts port
			end
			puts "Firewall denylist:"
			for ip in denied_ips do
				puts ip
			end
			puts "Would you like to configure the firewall accesslist and denylist before running the simulation? Y/N"
			answer = gets.chomp.strip.downcase
			while (answer != 'y') && (answer != 'n')
				puts "Please enter 'y' for yes or 'n' for no"
				answer = gets.chomp.strip.downcase
			end
			if answer == 'y'
				puts "Please enter the accepted ports as space separated port numbers"
				accepted_ports = gets.chomp.split.map(&:to_i)
				puts "Please enter the denied IP addresses as space separated IP addresses, e.g. 192.168.0.1 192.168.0.2"
				denied_ips = gets.chomp.split.map(&:strip)
			elsif answer == 'n'
				puts "Ok, the default accesslist and denylist will be used."
			end

			puts "client port: #{client_port}"
			puts "server port: #{server_port}"
			puts "Firewall accesslist: " 
			for port in accepted_ports do 
				puts port
			end
			puts "Firewall denylist:"
			for ip in denied_ips do
				puts ip
			end
			puts "Run the simulation with these configurations? y/n "
			answer = gets.chomp.strip.downcase
			while (answer != 'y') && (answer != 'n')
				puts "Please enter 'y' for yes or 'n' for no"
				answer = gets.chomp.strip.downcase
			end

			if (answer == 'y')
				run_simulation = true
			end
		end

		firewall = Firewall.new(accesslist: accepted_ports, denylist: denied_ips)
		server = SimulatedServer.new(client_port, server_port)
		client = SimulatedClient.new(server, firewall)
		client.run
	rescue Interrupt
		puts "\n\nProgram interrupted by user."
		exit 0
	rescue => e
		puts "\nError: #{e.message}"
		puts e.backtrace
		exit 1
	end

end