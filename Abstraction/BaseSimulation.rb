require_relative '../UI/UILogger'

class BaseSimulation


  # Used to construct the network stack for a simulation
  def initialize(stack = [])
    @stack = stack
    @current_layer_index = 0
    @current_protocol_data_unit = nil
    @tcp_handshake_completed = false
    @tls_handshake_completed = false

  end


  def perform_tcp_handshake
    raise NotImplementedError, "#{self.class} must implement #perform_tcp_handshake!"
  end

  def perform_tls_handshake
    raise NotImplementedError, "#{self.class} must implement #perform_tls_handshake!"
  end


  # Simulate sending data through the network stack starting from the top
  def send_data(data, start_index, end_index)

    log("Beginning a traversal of layers #{start_index} to #{end_index} with data #{data}")

    @current_protocol_data_unit = data


    while @current_layer_index > 0
      @current_protocol_data_unit = @stack[@current_layer_index].receive_from_next_upper_layer(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].encapsulate(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].send_to_next_lower_layer(@current_protocol_data_unit)
      @current_layer_index-=1
    end
  end





  # Simulate receiving data through the network stack starting from the bottom
  def receive_data(data, start_index, end_index)

    log("Beginning a traversal of layers #{start_index} to #{end_index} with data #{data}")

    @current_protocol_data_unit = data
    puts @current_protocol_data_unit
    @current_layer_index = 0

    while @current_layer_index <= @stack.length - 1
      @current_protocol_data_unit = @stack[@current_layer_index].receive_from_next_lower_layer(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].decapsulate(@current_protocol_data_unit)
      @current_protocol_data_unit = @stack[@current_layer_index].send_to_next_upper_layer(@current_protocol_data_unit)
      @current_layer_index+=1
    end
  end


  def log(data)
    UILogger::log(data)
  end

end