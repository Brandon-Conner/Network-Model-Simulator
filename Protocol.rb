
# Blueprint for creating a protocol that checks validity based on a set regular expression.
#
# Example : regex = /\A(?<method>[A-Z]+) (?<path>\/\S*) (?<version>HTTP\/\d\.\d)\z/;      SomeProtocol.new(regex)

module Protocol


  def initialize(regex)
    @regex = regex
    @regex_groups = {}
  end

  # Check the given expression against the regex and regex_groups set within the protocol definition
  def matches?(expression)
    m = @regex.match(expression)
    return false unless m

    m.named_captures.all? do |group_id_str, value|
      group_id = group_id_str.to_sym
      group = @regex_groups[group_id]
      next false unless group

      group.values.any? do |rule|
        rule.is_a?(Regexp) ? rule.match?(value) : value == rule.to_s
      end
    end
  end


  def add_regex_group(id)
    unless @regex_groups.key?(id)
      @regex_groups[id] ||= {}
    end
  end


  def add_to_group(group_id, element_id, regex)
    if @regex_groups.key?(group_id)
      @regex_groups[group_id][element_id] = regex
    end
  end




end