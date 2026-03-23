require_relative '../../Abstraction/eSimulation'
require_relative '../../OSI/Layer/OSIApplicationLayer/OSIApplicationLayer'
require_relative '../../OSI/Layer/OSIDataLinkLayer'
require_relative '../../OSI/Layer/OSITransportLayer'
require_relative '../../OSI/Layer/OSINetworkLayer'
require_relative '../../OSI/Layer/OSIPresentationLayer'
require_relative '../../OSI/Layer/OSISessionLayer'
require_relative '../../OSI/Layer/OSIPhysicalLayer'

# example use : call send method with argument : GET /https://www.google.com HTTP/1.1

class OSISimulation < BaseSimulation

  def initialize
    super(
      [OSIPhysicalLayer.new,
       OSIDataLinkLayer.new,
       OSITransportLayer.new,
       OSINetworkLayer.new,
       OSISessionLayer.new,
       OSIPresentationLayer.new,
       OSIApplicationLayer.new,
      ]
    )
    @current_layer_index = 0
    @current_protocol_data_unit = nil
  end


  def send(data)
    @current_protocol_data_unit = data
    puts @current_protocol_data_unit
    @current_layer_index = @stack.length - 1

    while (@current_layer_index > 0)
      @current_protocol_data_unit = @stack[@current_layer_index].receive_from_next_upper_layer(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].encapsulate(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].send_to_next_lower_layer(@current_protocol_data_unit)
      @current_layer_index=-1
    end
  end



  def receive(data)

  end


end