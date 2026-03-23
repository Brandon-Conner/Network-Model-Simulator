require_relative './Output'

class UserInterface

  DEFAULT_EXIT_CODE = 'q'

  def initialize

  end


  # run the user interfaces program introduction
  def run_program_introduction
    Output::print_with_delay("This program simulates data transfer through the layers of the network stack.")
    Output::print_with_delay "You can choose to either simulate the OSI stack or the TCP/IP stack."
  end


  def osi_or_tcp?
    get_valid_user_input("Would you like to simulate the OSI or TCP/IP network stack?",
                         ["osi", "tcp"])
  end

  def send_or_receive?
    get_valid_user_input("Would you like to simulate sending data(sending data downwards) or receiving data(sending data upwards)?",
                         ["send", "receive"])
  end

  def get_data_from_user_to_send
    Output::print_with_delay("Enter the data to send")
    gets.chomp
  end

  def get_data_from_user_to_receive
    Output::print_with_delay("Enter the data to receive")
    gets.chomp
  end


  # Loop printing the provided prompt, getting user input and returning only when user input matches a provided valid response
  def get_valid_user_input(prompt, valid_responses =[])
    user_choice = nil
    until valid_responses.include?(user_choice)  || user_choice == DEFAULT_EXIT_CODE
      Output::print_with_delay(prompt)
      Output::print_with_delay(" -enter: ")
      valid_responses.each do |response| print " [#{response}] " end
      puts # Empty line
      Output::print_with_delay(" [#{DEFAULT_EXIT_CODE}] to exit program.")
      user_choice = gets.chomp
      if user_choice == DEFAULT_EXIT_CODE; exit; end # Make sure user can't get stuck in a loop
    end
    user_choice # return the valid user input
  end
end