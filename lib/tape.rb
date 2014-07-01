require_relative './rotatable'

class Tape
  include Rotatable

  attr_accessor :current_index, :component_spacing

  def self.from_config(attrs)
    tape = Tape.new attrs.slice(:rotation, :component_spacing)
    [:x, :y, :z].each do |k|
      tape.send :"relative_#{k}=", attrs[k]
    end
    return tape
  end

  def initialize(attrs)
    self.current_index = -1
    attrs.each { |k, v| self.send :"#{k}=", v }
  end

  def next_component
    # incrementing the tape position
    self.current_index += 1
    return Component.new(
      relative_x: current_index * component_spacing,
      parent: self
    )
  end

end