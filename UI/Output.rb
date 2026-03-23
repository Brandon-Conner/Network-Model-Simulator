
module Output

  DEFAULT_DELAY = 0.2

  @delay
  def self.delay
    @delay
  end

  def self.delay=(delay)
    @delay = delay
  end


  # print a message to console with a default delay time
  def self.print_with_delay(message, delay = @delay)
    puts message
    if @delay.nil?;      delay = DEFAULT_DELAY;   end
    sleep(delay)
  end

end