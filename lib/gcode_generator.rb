require 'yaml'
require_relative './models/tape'

class GCodeGenerator
  attr_reader :layout, :gcodes, :yml

  delegate :tapes, :to => :layout

  def initialize(layout, yml)
    @xy = [:x, :y]
    @xyz = [:x, :y, :z]
    @layout = layout
    @yml = yml
  end

  def run
    @gcodes = []
    @gcodes = @gcodes.concat yml[:gcode][:before].split "\n"
    move z: yml[:z_travel_height]
    # Running through each board instance in the layout
    layout.each_board_position do |board, index|
      comment "Board ##{index}", :h1
      # Adding the components of this board instance
      board.components.sort_by {|c| [c.x, c.y]}.each do |c|
        add_component(c) if c.package.present? and c.layer == board.layer.to_sym
      end
    end
    @gcodes = @gcodes.concat yml[:gcode][:after].split "\n"
    return self
  end

  def write(file_name)
    File.open(file_name, 'w') { |file| file.write(gcodes.join("\n")) }
  end

  private

  def add_component(component)
    tape_id = component.tape_id
    tape = tapes[tape_id][component.rotation.round]
    return if tape.blank?
    # Commenting the GCode
    comment "#{tape_id} ##{tape.current_index}", :h2
    # Pick up the component from the tape
    move_to_component_and_up tape.next_component
    # Move the component into position and place it
    move_to_component_and_up component
  end

  def move_to_component_and_up(component)
    move x: component.x, y: component.y
    move z: component.z
    move z: yml[:z_travel_height]
  end

  # Add a comment line to the gcode
  def comment(text, level)
    text = "; #{text}"
    text = "\n#{text}" if level == :h2
    text = "\n\n#{text}" if level == :h1
    gcodes << text
  end

  # Adds a move command (G1) to the gcode (takes absolute positions)
  def move(axes)
    gcode = "G1"
    axes.each do |k, position|
      gcode += " #{k.upcase}#{(position * yml[:scale][k]).round(2)}"
    end
    gcode += " F#{yml[:feedrate]}"
    gcodes << gcode
  end

end
