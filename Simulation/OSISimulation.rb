require_relative '../Abstraction/BaseSimulation'
require_relative '../OSI/Layer/OSIApplicationLayer/OSIApplicationLayer'
require_relative '../OSI/Layer/OSIDataLinkLayer'
require_relative '../OSI/Layer/OSITransportLayer'
require_relative '../OSI/Layer/OSINetworkLayer'
require_relative '../OSI/Layer/OSIPresentationLayer'
require_relative '../OSI/Layer/OSISessionLayer'
require_relative '../OSI/Layer/OSIPhysicalLayer'

# This is the first version of OSISimulation which currently only handles the HTTPS protocol.
# example use : call send method with argument : GET /https://www.google.com HTTP/1.1

class OSISimulation < BaseSimulation

  def initialize
    super(
      [OSIPhysicalLayer.new,
       OSIDataLinkLayer.new,
       OSINetworkLayer.new,
       OSITransportLayer.new,
       OSISessionLayer.new,
       OSIPresentationLayer.new,
       OSIApplicationLayer.new
      ]
    )
    @current_layer_index = 0
    @current_protocol_data_unit = nil
  end


  def send(data)
    @current_protocol_data_unit = data
    puts @current_protocol_data_unit
    @current_layer_index = @stack.length - 1

    while @current_layer_index >= 0

      if @stack[@current_layer_index].is_a?(OSISessionLayer) && @current_protocol_data_unit[:protocol_id] == "HTTPS"
        if @stack[@current_layer_index - 1].tcp_state_machine.state == :established
          @stack[@current_layer_index].perform_tls_handshake
        else
          @stack[@current_layer_index - 1].perform_tcp_handshake
        end
      end

      @current_protocol_data_unit = @stack[@current_layer_index].receive_from_next_upper_layer(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].encapsulate(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].send_to_next_lower_layer(@current_protocol_data_unit)
      @current_layer_index-=1
      if (@current_layer_index == -1); puts "The data has left the senders network stack"
      else puts "From OSISimulation: Current Layer -> #{ @current_layer_index +1 }"
      end
    end
    @current_protocol_data_unit = nil
  end



  def receive(data)
    @current_protocol_data_unit = data
    puts @current_protocol_data_unit
    @current_layer_index = 0

    while @current_layer_index <= @stack.length - 1
      @current_protocol_data_unit = @stack[@current_layer_index].receive_from_next_lower_layer(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].decapsulate(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].send_to_next_upper_layer(@current_protocol_data_unit)
      @current_layer_index+=1
    end
    @current_protocol_data_unit = nil
  end


end