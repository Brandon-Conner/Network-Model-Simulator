require_relative '../BaseNetworkLayer'

# Physical Layer(1) of the OSI network model
class OSIPhysicalLayer < BaseNetworkLayer


	def initialize

	end

	def add_header

	end

	def strip_header(data)

	end

	def send_to_next_upper_layer(data)

	end

	def send_to_next_lower_layer(data)

	end

	# Accepts frames from the data link layer and converts them into "bits"
	# —a stream of electrical, optical, or radio signals —for transmission across the physical medium.
	def receive_from_next_upper_layer(data)

	end

	def receive_from_next_lower_layer(data)

	end

	def log(data)
		puts "The data: #{data} at this layer is represented as a series of high and low intensity signals."
	end

end
