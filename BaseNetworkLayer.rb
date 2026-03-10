require_relative 'NetworkLayer'
=begin
	abstraction module for representing a distinct layer of the network stack
=end

class BaseNetworkLayer
	include NetworkLayer
	# Dynamically typed data structure for holding instance data if a layer needs to be stateful
	attr_accessor :data

	# Constructor
	def initialize

	end


	# Base implementation for logging data, logs data sent with log function if it exists(!=nil),
	# along with state data kept within the data instance variable for BaseNetworkLayer if it exists(!=nil).
	def log(data)
		puts "Log:"
		if data != nil;        puts("#{data}");        else        puts("-No data provided with log function call"); end
		if @data != nil;       puts("#{@data}");       else        puts("-Layer contains no state data for BaseNetworkLayer.data"); end
	end


end # End of BaseNetworkLayer