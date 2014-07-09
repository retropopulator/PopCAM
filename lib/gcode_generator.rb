require 'yaml'
require_relative './tape'

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
    @tapes = {}
    @layout[:tapes].each  do |k, attrs|
      tape = Tape.from_config(k, attrs)
      @tapes[tape.id] = tape
    end
  end

  def run
    @gcodes = []
    @gcodes = @gcodes.concat @layout[:gcode][:before].split "\n"
    move z: @layout[:z_travel_height]
    # Running through each board instance in the layout
    @layout[:boards].each_with_index do |board_position, index|
      comment "Board ##{index}", :h1
      # Repositioning the board for this board_position
      board.set_position! board_position.symbolize_keys
      # Adding the components of this board instance
      board.components.sort_by {|c| [c.x, c.y]}.each do |c|
        add_component(c) if c.package.present? and c.layer == board.layer.to_sym
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
    tape_id = component.tape_id
    tape = @tapes[tape_id]
    msg = "#{"#{component.name} ".ljust(20, '.')} #{tape_id}"
    return puts "[ #{"MISS".red()} ] #{msg}" if tape.blank?
    puts "[ #{"OK".greenish()}   ] #{msg}"
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
    move z: @layout[:z_travel_height]
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
      gcode += " #{k.upcase}#{(position * @layout[:scale][k]).round(2)}"
    end
    gcode += " F#{@layout[:feedrate]}"
    gcodes << gcode
  end

end
