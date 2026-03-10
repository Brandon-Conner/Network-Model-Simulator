
require_relative 'BaseSimulation'
require_relative '../OSI/OSIApplicationLayer/OSIApplicationLayer'
require_relative '../OSI/OSIDataLinkLayer'
require_relative '../OSI/OSITransportLayer'
require_relative '../OSI/OSINetworkLayer'
require_relative '../OSI/OSIPresentationLayer'
require_relative '../OSI/OSISessionLayer'
require_relative '../OSI/OSIPhysicalLayer'

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
  end


  def start_simulation_sending_data(data)
    send_data(data)
  end

  def start_simulation_receiving_data(data)
    receive_data(data)
  end


end