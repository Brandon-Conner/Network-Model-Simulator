
=begin
Accepts data from the session layer and segments it,
adding a header that includes source/destination port numbers.
TCP uses "segments" (for reliability), while UDP uses "datagrams".
=end

require_relative '../../Abstraction/NetworkLayer'


class OSITransportLayer < BaseNetworkLayer

  def initialize

  end


  def encapsulate(data)

  end

  def decapsulate(data)

  end

  def send_to_next_upper_layer(data)

  end

  def send_to_next_lower_layer(data)

  end

  def receive_from_next_upper_layer(data)

  end

  def receive_from_next_lower_layer(data)

  end

  def log(data)

  end



  # Helper class for managing TCP connection state
  class TcpStateMachine
    STATES = {
      closed:       :closed,
      syn_sent:     :syn_sent,
      syn_received: :syn_received,
      established:  :established
    }.freeze

    attr_reader :state

    def initialize
      @state = STATES[:closed]
    end

    def send_syn!
      raise "invalid transition" unless @state == STATES[:closed]
      @state = STATES[:syn_sent]
    end

    def recv_syn!
      raise "invalid transition" unless @state == STATES[:closed]
      @state = STATES[:syn_received]
    end

    def recv_syn_ack!
      raise "invalid transition" unless @state == STATES[:syn_sent]
      @state = STATES[:established]
    end

    def send_ack!
      raise "invalid transition" unless @state == STATES[:syn_received]
      @state = STATES[:established]
    end

    def established?
      @state == STATES[:established]
    end
  end

end