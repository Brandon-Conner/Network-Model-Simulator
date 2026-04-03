require_relative './NetworkLayer'
require_relative '../UI/UILogger'
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
		if data.nil?
			log("No data provided to #{__method__}");
		else
			log(data)
			data
		end
	end

	def send_to_next_upper_layer( data )
		if data.nil?
			log("No data provided to #{__method__}");
		else
			log(data)
			data
		end
	end

	def receive_from_next_upper_layer(data)
		if data.nil?
			log("No data provided to #{__method__}");
		else
			log(data)
			data
		end
	end

	def receive_from_next_lower_layer(data)
		if data.nil?
			log("No data provided to #{__method__}");
		else
			data
		end
	end


	def log(data)
		# Get the direct caller's location
		caller_info = caller_locations(2, 1)[0]

		method = caller_info.label
		file = File.basename(caller_info.path)
		line = caller_info.lineno

		data_to_string = String.new
		if data.is_a?(Hash)
			data.each do |key, value|
				data_to_string << "#{key}:#{value}"
			end
		elsif data.is_a?(String)
			data_to_string << data
		end

		UILogger::log(" method[#{method}] in file[#{file}] at line[#{line}] with payload[#{data_to_string}]\n")
	end


end # End of BaseNetworkLayer