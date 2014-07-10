require_relative './rotatable'

# General purpose rotatable.
class Offset
  include Rotatable

  def initialize(attrs)
    set_position! attrs
  end
end