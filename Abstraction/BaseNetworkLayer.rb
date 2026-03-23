require_relative './NetworkLayer'
=begin
	abstraction module for representing a distinct layer of the network stack
=end

class BaseNetworkLayer
	include NetworkLayer
	# Dynamically typed data structure for holding instance data if a layer needs to be stateful
	attr_accessor :data

	# Constructor
	def initialize
		@data = {}
	end


	def send_to_next_lower_layer( data )
		if data.nil? log("No data provided to #{__method__}"); end
	end

	def send_to_next_upper_layer( data )
		if data.nil? log("No data provided to #{__method__}"); end
	end

	def receive_from_next_upper_layer(data)
		if data.nil? log("No data provided to #{__method__}"); end
	end

	def receive_from_next_lower_layer(data)
		if data.nil? log("No data provided to #{__method__}"); end
		end

	# Base implementation for logging data, logs data sent
	def log(data)
		location = caller_locations(1, 1)[0]
		filename = File.basename(location.path)
		method_name = location.label
		Output::print_with_delay("=>Log:: #{data} @[#{filename}:#{method_name}]")
	end


end # End of BaseNetworkLayer