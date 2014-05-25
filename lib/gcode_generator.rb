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
    @layout[:strips].each {|k, strip| strip[:next_index] = 0}
  end

  def run
    @gcodes = []
    @gcodes = @gcodes.concat @layout[:gcode][:before].split "\n"
    move z: @layout[:z_travel_height]
    board.components.sort_by {|c| c[:package][:name]}.each do |c|
      add_component(c) if c[:package].present?
    end
    return self
  end

  def write(file_name)
    File.open(file_name, 'w') { |file| file.write(gcodes.join("\n")) }
  end

  private

  def add_component(c)
    pkg_name = c[:package][:name]
    strip = @layout[:strips][pkg_name.to_sym]
    return puts "Missing strip for #{pkg_name}. Skipping." if strip.blank?
    # calculating the strip index and x, y and z position
    strip_index = strip[:next_index]
    strip_position = strip.slice(*@xyz)
    strip_position[:y] += strip[:component_spacing] * strip[:next_index]
    # calculating the absolute component position (part offset + component
    # position)
    c_position = {}
    @xyz.each {|k| c_position[k] = @layout[:part][k] + (c[k]||0) }
    # adding the GCode
    add_component_gcode(pkg_name, strip, strip_position, c_position)
    # incrementing the strip position
    strip[:next_index] += 1
  end

  def add_component_gcode(pkg_name, strip, strip_position, c_position)
    # Commenting the GCode
    gcodes << "\n; #{pkg_name} ##{strip[:next_index]}"
    # Pick up the component
    move strip_position.slice(*@xy)
    move strip_position.slice :z
    move z: @layout[:z_travel_height]
    # Move the component into position and place it
    move c_position.slice(*@xy)
    move c_position.slice :z
    move z: @layout[:z_travel_height]
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
