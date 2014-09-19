require_relative './rotatable'
require_relative './offset'

class Tape
  include Rotatable

  attr_accessor :id, :current_index, :component_spacing

  def initialize(id, attrs)
    self.current_index = 0
    self.id = id
    self.component_spacing = attrs[:component_spacing]
    self.parent = Offset.new attrs
    # ap attrs
    # ap self.x
    set_position!(
      y: attrs[:tape_spacing] * attrs[:index],
      rotation: 0
    )
  end

  def next_component
    inversion = parent.inverted ? -1 : 1
    component = Component.new
    # ap current_index * component_spacing * inversion
    component.set_position!(
      x: current_index * component_spacing * inversion,
      rotation: 0
    )
    # incrementing the tape position
    self.current_index += 1
    return component
  end
end
