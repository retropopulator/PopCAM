require 'yaml'

class GCodeGenerator
  attr_reader :layout, :gcodes, :board

  def initialize(opts)
    @xy = [:x, :y]
    @xyz = [:x, :y, :z]
    @current_direction = {x: -1, y: -1, z: -1}
    @current_position = {x: 0, y: 0, z: 0}
    @opts = opts
    @board = opts[:board]
    @layout = YAML::load_file(@opts[:layout_file]).deep_symbolize_keys
    @layout[:tapes].each {|k, tape| tape[:next_index] = 0}
  end

  def run
    @gcodes = []
    @gcodes = @gcodes.concat @layout[:gcode][:before].split "\n"
    move z: @layout[:z_travel_height]
    # Running through each board instance in the layout
    @layout[:boards].each_with_index do |board_position, index|
      comment "Board ##{index}", :h1
      board.set_position! board_position.symbolize_keys
      ap board.absolute_coordinates
      # Adding the components of this board instance
      board.components.sort_by {|c| [c.x, c.y]}.each do |c|
        add_component(c) if c.package.present?
      end
    end
    @gcodes = @gcodes.concat @layout[:gcode][:after].split "\n"
    return self
  end

  def write(file_name)
    File.open(file_name, 'w') { |file| file.write(gcodes.join("\n")) }
  end

  private

  def add_component(component)
    pkg_name = component.package[:name]
    tape = @layout[:tapes][pkg_name.to_sym]
    return puts "Missing tape for #{pkg_name}. Skipping." if tape.blank?
    # calculating the tape index and x, y and z position
    tape_index = tape[:next_index]
    tape_position = tape.slice(*@xyz)
    tape_position[:y] += tape[:component_spacing] * tape[:next_index]
    # adding the GCode
    add_component_gcode(pkg_name, tape, tape_position, component)
    # incrementing the tape position
    tape[:next_index] += 1
  end

  def add_component_gcode(pkg_name, tape, tape_position, component)
    # Commenting the GCode
    comment "#{pkg_name} ##{tape[:next_index]}", :h2
    # Pick up the component
    # move tape_position.slice(*@xy)
    # move tape_position.slice :z
    # move z: @layout[:z_travel_height]
    # # Move the component into position and place it
    move x: component.x, y: component.y
    # move z: component.z
    # move z: @layout[:z_travel_height]
  end

  # Add a comment line to the gcode
  def comment(text, level)
    text = "; #{text}"
    text = "\n #{text}" if level == :h2
    text = "\n\n #{text}" if level == :h1
    gcodes << text
  end

  # Adds a move command (G1) to the gcode (takes absolute positions)
  def move(axes)
    gcode = "G1"
    axes.each do |k, position|
      # converting the absolute position to a relative position
      relative_position = position - @current_position[k]
      @current_position[k] = position
      # Adding backlash and scaling
      relative_position += backlash(k, relative_position)
      gcode += " #{k.upcase}#{relative_position * @layout[:scale][k]}"
    end
    gcode += " F#{@layout[:feedrate]}"
    gcodes << gcode
  end

  def backlash(axis, value)
    direction = value > 0 ? 1 : -1
    if @current_direction[axis] == direction
      return 0
    else
      @current_direction[axis] *= -1
      return @layout[:backlash][axis] * direction
    end
  end
end
