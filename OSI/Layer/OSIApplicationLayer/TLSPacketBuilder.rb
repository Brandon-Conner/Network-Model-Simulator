
require 'openssl'

class TLSPacketBuilder

	# TLS Record content types
	RECORD_HANDSHAKE     = 0x16
	RECORD_APPLICATION   = 0x17
	RECORD_CHANGE_CIPHER = 0x14

	# TLS 1.2 version
	TLS_VERSION_12 = [0x03, 0x03]

	CIPHER_SUITE_TLS_RSA_WITH_AES_128_CBC_SHA = 0x002F

	# Hard-coded key/IV from key exchange in real TLS
	AES_128_KEY = "0123456789abcdef".b
	AES_128_IV  = "fedcba9876543210".b

	# Handshake message types
	HANDSHAKE_CLIENT_HELLO      = 0x01
	HANDSHAKE_SERVER_HELLO      = 0x02
	HANDSHAKE_CERTIFICATE       = 0x0B
	HANDSHAKE_SERVER_HELLO_DONE = 0x0E
	HANDSHAKE_CLIENT_KEY_EXCHG  = 0x10
	HANDSHAKE_FINISHED          = 0x14

	#______________________________________________________________________________________________
	#                   W R A P   M E S S A G E   I N   T L S   R E C O R D
	# Add a 5 byte tls record header to all messages
	# ____________________________________________________________________________________________
	def wrap_message_in_tls_record(content_type, payload)
		# Record: [ContentType:1][Version:2][Length:2][Payload]
		length = payload.bytesize
		header = [content_type, *TLS_VERSION_12, (length >> 8) & 0xFF, length & 0xFF].pack('CCCCC')
		header + payload
	end

	#______________________________________________________________________________________________
	#                             S T E P - 1     C L I E N T   H E L L O
	# 	Send to server:
	# 		- Supported TLS versions
	# 		- Supported cipher suites
	# 		- A random number (Client Random)
	# 		- Key share (for key exchange, e.g., ECDHE)
	# 		- Supported extensions (SNI, ALPN, etc.)
	# _____________________________________________________________________________________________
	def client_hello(hostname = "tulsa.okstate.edu", cipher_suites = [0x002F])
		cipher_suites_bytes = cipher_suites.map { |cs| [(cs >> 8) & 0xFF, cs & 0xFF].pack('CC') }.join
		random = (0...32).map { rand(256) }.pack('C*')
		session_id = ""
		compression = 0x00
		body = [0x03, 0x03].pack('CC') + random
		body << session_id.bytesize.chr
		body << session_id
		body << [cipher_suites_bytes.bytesize].pack('n')
		body << cipher_suites_bytes
		body << 1.chr
		body << compression.chr
		body << build_sni_extension(hostname)
		handshake = HANDSHAKE_CLIENT_HELLO.chr + [body.bytesize].pack('N')[1, 3] + body
		wrap_message_in_tls_record(RECORD_HANDSHAKE, handshake)
	end

	#______________________________________________________________________________________________
	#                             S T E P - 2     S E R V E R   H E L L O
	# Selected TLS version
	# Selected cipher suite
	# Server random
	# Its key share
	# Its digital certificate
	# _____________________________________________________________________________________________
	def server_hello(selected_cipher_suite = 0x002F)
		cipher_suite_bytes = [(selected_cipher_suite >> 8) & 0xFF, selected_cipher_suite & 0xFF].pack('CC')
		random = (0...32).map { rand(256) }.pack('C*')
		session_id = ""
		compression = 0x00
		body = [0x03, 0x03].pack('CC') + random
		body << session_id.bytesize.chr
		body << session_id
		body << cipher_suite_bytes
		body << compression.chr
		body << build_simple_extensions
		handshake = HANDSHAKE_SERVER_HELLO.chr + [body.bytesize].pack('N')[1, 3] + body
		wrap_message_in_tls_record(RECORD_HANDSHAKE, handshake)
	end


	#______________________________________________________________________________________________
	#                S T E P - 3     C E R T I F I C A T E   V E R I F I C A T I O N
	# Client validates server certificate
	# _____________________________________________________________________________________________
	def verify_certificate(cert_data)
		return true if cert_data && cert_data.bytesize > 0							# Simulation: no packet; returns true if valid
		false
	end


	#______________________________________________________________________________________________
	#                          S T E P - 4     K E Y   E X C H A N G E
	# Client sends encrypted key
	# _____________________________________________________________________________________________
	def key_exchange
		# Client Key Exchange: encrypted premaster secret (simplified as placeholder)
		# For RSA: [EncryptedPremasterLen:2][EncryptedPremaster]
		premaster = (0...48).map { rand(256) }.pack('C*')  # Placeholder
		body = [premaster.bytesize].pack('n') + premaster
		handshake = HANDSHAKE_CLIENT_KEY_EXCHG.chr + [body.bytesize].pack('N')[1, 3] + body
		wrap_message_in_tls_record(RECORD_HANDSHAKE, handshake)
	end


	#______________________________________________________________________________________________
	#   S T E P - 5     S E S S I O N   C O M P L E T E   /   F I N I S H E D   M E S S A G E S
	# Change Cipher Spec (switch to encrypted mode)
	# Finished message (verifies handshake integrity)
	# Session established, ready for application data
	# _____________________________________________________________________________________________
	def tls_finished
		ccs = [0x01].pack('C') 		# Change Cipher Spec: single byte 0x01
		ccs_record = wrap_message_in_tls_record(RECORD_CHANGE_CIPHER, ccs) 		# Finished: 12-byte verify_data (placeholder)
		verify_data = (0...12).map { rand(256) }.pack('C*')
		finished = HANDSHAKE_FINISHED.chr + [verify_data.bytesize].pack('N')[1, 3] + verify_data
		finished_record = wrap_message_in_tls_record(RECORD_HANDSHAKE, finished)
		ccs_record + finished_record
	end


	#______________________________________________________________________________________________
	#                                     E N C R Y P T   R E Q U E S T
	# - Wraps plaintext (e.g., HTTP request) in TLS Application Data record
	# - Content type 0x17 (Application Data)
	# - Adds record header (type + version + length)
	# _____________________________________________________________________________________________
	def encrypt_request(plaintext)
		cipher = OpenSSL::Cipher.new('AES-128-CBC')
		cipher.encrypt
		cipher.key = AES_128_KEY
		cipher.iv  = AES_128_IV
		encrypted = cipher.update(plaintext) + cipher.final
		wrap_message_in_tls_record(RECORD_APPLICATION, encrypted)
	end


	#______________________________________________________________________________________________
	#                                      D E C R Y P T   R E Q U E S T
	# - Strips TLS record header from received data
	# - Decrypts payload using session keys
	# - Returns plaintext application data
	# _____________________________________________________________________________________________
	def decrypt_request(record)
		return "".b if record.bytesize < 5
		payload = record.byteslice(5..-1)
		cipher = OpenSSL::Cipher.new('AES-128-CBC')
		cipher.decrypt
		cipher.key = AES_128_KEY
		cipher.iv  = AES_128_IV
		cipher.update(payload) + cipher.final
	rescue OpenSSL::Cipher::CipherError
		"".b  # or re-raise, or log
	end


	# Helper functions
	private
	def build_sni_extension(hostname)
		# SNI: Server Name Indication
		# [ExtType:2][ExtLen:2][SNIListLen:2][HostNameType:1][HostNameLen:2][HostName]
		sni_data = 0x00.chr + [hostname.bytesize].pack('n') + hostname
		list = [sni_data.bytesize].pack('n') + sni_data
		ext = [0x0000].pack('n') + [list.bytesize].pack('n') + list
		ext
	end

	def build_simple_extensions
		[0x00, 0x00].pack('n')  		# Minimal extensions placeholder
	end

end # End of TLSPacketBuilder