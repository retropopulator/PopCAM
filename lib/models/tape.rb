require_relative './rotatable'
require_relative './offset'

class Tape
  include Rotatable

  attr_accessor :id, :current_index, :component_spacing

  def initialize(id, attrs)
    self.current_index = -1
    self.id = id
    self.component_spacing = attrs[:component_spacing]
    self.parent = Offset.new attrs
    set_position!(
      y: (attrs[:tape_spacing]||0) * attrs[:index]
    )
  end

  def next_component
    # incrementing the tape position
    self.current_index += 1
    return Component.new(
      relative_x: current_index * component_spacing * (parent.inverted ? -1 : 1),
      parent: self
    )
  end
end