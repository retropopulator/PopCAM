require_relative './rotatable'

class Tape
  include Rotatable

  attr_accessor :id, :current_index, :component_spacing

  def self.from_config(id, attrs)
    tape = Tape.new id, attrs.slice(:component_spacing)
    [:x, :y, :z, :rotation].each do |k|
      tape.send :"relative_#{k}=", attrs[k]
    end
    return tape
  end

  def initialize(id, attrs)
    self.current_index = -1
    self.id = id
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