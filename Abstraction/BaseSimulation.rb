require_relative '../UI/roject2/UI/Output'

class BaseSimulation


  # Used to construct the network stack for a simulation
  def initialize(stack = [])
    @stack = stack
  end


  # Simulate sending data through the network stack starting from the top
  def send_data(data)

    data_ref = data

    top_layer_index = @stack.length - 1 # Set the top layer index to stack length - 1

    @stack[top_layer_index].receive_from_next_upper_layer(data) # Call receive on the top layer(input validation)


    top_layer_index.downto(1) do |index| # Send the data down the layers
      # Send the data to the next lower layer
      data = @stack[index].encapsulate(data)
      @stack[index - 1].receive_from_next_upper_layer(  @stack[index].send_to_next_lower_layer(data)  )
    end

    data = @stack[0].encapsulate(data)
    @stack[0].send_to_next_lower_layer( data ) # Return the data from the bottom layer
    Output::print_with_delay("Bottom layer sent data: #{data}")
  end





  # Simulate receiving data through the network stack starting from the bottom
  def receive_data(data)

    top_layer_index = @stack.length - 1

    0.upto(top_layer_index - 1) do |index|  # iterate through the layers
      @stack[index + 1].receive_from_next_lower_layer(@stack[index].send_to_next_upper_layer(@stack[index].decapsulate(data)) ) # send the data to the layer above
    end

    @stack[top_layer_index].send_to_next_lower_layer(@stack[top_layer_index].decapsulate(data)) # Return the data from the top layer
    Output::print_with_delay("Top layer received data: #{data}")
  end


end