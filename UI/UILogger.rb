require_relative 'Output'

module UILogger
  include Output

  def self.log(data)
    Output::print_with_delay("LOG -> " + data)
  end

end