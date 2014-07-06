module Rotatable
  attr_accessor(
    :relative_x, :relative_y, :relative_z, :rotation, :parent, :layer
  )

  # Absolute x coordinate
  def x
    absolute_coordinates[:x]
  end

  # Absolute y coordinate
  def y
    absolute_coordinates[:y]
  end

  # Absolute z coordinate
  def z
    absolute_coordinates[:z]
  end

  # Memoized sin rotation value
  def sin_r
    @sin_theta = Math::sin(rotation * Math::PI / 180  || 0)
  end

  # Memoized cos rotation value
  def cos_r
    @cos_theta = Math::cos(rotation * Math::PI / 180  || 0)
  end

  def rotation=(val)
    @rotation = val
    @cos = nil
    @sin = nil
  end

  # Move the rotatable piece and reset it's memoized values
  def set_position!(coords)
    @relative_x = coords[:x] || 0
    @relative_y = coords[:y] || 0
    @relative_z = coords[:z] || 0
    self.layer = coords[:layer]
    self.rotation = coords[:rotation] || 0
    mark_as_dirty!
  end

  def mark_as_dirty!
    @abs_coords = nil
  end

  def coordinates_dirty?
    @abs_coords.blank? or (parent.present? and parent.coordinates_dirty?)
  end

  def relative_x
    @relative_x || 0
  end

  def relative_y
    @relative_y || 0
  end

  def relative_z
    @relative_z || 0
  end

  def absolute_coordinates
    return @abs_coords unless coordinates_dirty?
    if parent.present?
      @abs_coords = {
        x: parent.x + relative_x * parent.cos_r - relative_y * parent.sin_r,
        y: parent.y + relative_x * parent.sin_r + relative_y * parent.cos_r,
        z: parent.z + relative_z
      }
    else
      @abs_coords = {x: relative_x, y: relative_y, z: relative_z}
    end
    return @abs_coords
  end

end