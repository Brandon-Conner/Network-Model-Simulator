
=begin
  This is the layer where tls encryption/decryption occurs, for the simulation we assume that all data sent from this
  layer is encrypted with tls. The entire handshake sequence is initiated here and each step in the process moves
  through layers 1-5. Utilizes protocol version negotiation to use the latest and most secure version of TLS that
  is accepted by the server. This simulation explicitly uses the TLS 1.2 protocol, but only proceeds if the server
  agrees to use it.

=end

require_relative '../../Abstraction/NetworkLayer'

class OSISessionLayer < BaseNetworkLayer


  TLS_VERSION_10 = [0x03, 0x01] # TLS version 1.0
  TLS_VERSION_11 = [0x03, 0x02] # TLS version 1.1
  TLS_VERSION_12 = [0x03, 0x03] # TLS version 1.2

  COMPATIBLE_TLS_VERSIONS = ["TLS_1.0", "TLS_1.1", "TLS_1.2"]

  attr_reader :tls_state_machine

  def initialize
    @tls_handshake_completed = false
    @tls_state_machine = TlSStateMachine.new
  end


  def encapsulate(data)
    log(data)
    data
  end


  def decapsulate(data)
    log(data)
    data
  end


  def send_to_next_upper_layer(data)
    log(data)
    data
  end

  def send_to_next_lower_layer(data)
    log(data)
    data
  end

  # receive data from presentation layer. Perform tls handshake and encrypt data
  def receive_from_next_upper_layer(data)

    if data.nil?; log("Data received from presentation layer is null")
    else log("Received data from presentation layer: #{data}")
    end
    @data = data

    if tls_state_machine.established?
      @data
    end

    if @data.is_a?(Hash)
      protocol_id = @data[:protocol_id]
    else
      protocol_id = nil
    end

    if @data.is_a?(Hash) && @data[:protocol_id] == "HTTPS"
      perform_tls_handshake('TLS_1.2')
      @data
    end
  end


  def perform_tls_handshake(version)
      log("Beginning TLS handshake")
      tls_state_machine.sent_client_hello!;        log('client hello success')
      tls_state_machine.received_server_hello!;    log('server hello success')
      tls_state_machine.keys_exchanged!;           log('keys exchanged success')
      tls_state_machine.established!;              log('connection established success')
  end

  def tls_version_is_compatible?(version)
    if COMPATIBLE_TLS_VERSIONS.include?(version)
    end
  end

  def receive_from_next_lower_layer(data)

  end

  def log(data)
    super(data)
  end



  # Helper class for TLS status
    class TlSStateMachine
      STATES = {
        new:                    :new,
        client_hello_sent:      :client_hello_sent,
        server_hello_received:  :server_hello_received,
        keys_exchanged:         :keys_exchanged,
        established:            :established
      }.freeze

      attr_reader :state

      def initialize
        @state = STATES[:new]
      end

      def sent_client_hello!
        raise "invalid transition" unless @state == STATES[:new]
        @state = STATES[:client_hello_sent]
      end

      def received_server_hello!
        raise "invalid transition" unless @state == STATES[:client_hello_sent]
        @state = STATES[:server_hello_received]
      end

      def keys_exchanged!
        raise "invalid transition" unless @state == STATES[:server_hello_received]
        @state = STATES[:keys_exchanged]
      end

      def established!
        raise "invalid transition" unless @state == STATES[:keys_exchanged]
        @state = STATES[:established]
      end

      def established?
        @state == STATES[:established]
      end
    end

end