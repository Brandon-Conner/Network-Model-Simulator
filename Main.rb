
require_relative 'UserInterface'
require_relative 'Simulation/OSISimulation'
require_relative 'Simulation/TCPIPSimulation'

class Main

  def initialize

    ui = UserInterface.new
    ui.run_program_introduction
    model_type = ui.osi_or_tcp?
    action_type = ui.send_or_receive?
    simulation = nil
    data = nil

    case
    when model_type == "osi"
      puts "model - OSI"

      simulation = OSISimulation.new

      case
      when action_type == "send";
        puts "type - sending data"
        data = ui.get_data_from_user_to_send
        simulation.send_data(data)

      when action_type == "down"

      else puts "Couldn't determine direction"
      end


    when model_type == "tcp"
      puts "tcp"

      case
      when action_type == "up"

      when action_type == "down"

      else puts "Couldn't determine direction"
      end

    else
      puts "Couldn't determine model type"
    end
  end


end
