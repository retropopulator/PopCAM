require_relative './rotatable'

class Component
  include Rotatable

  attr_accessor :package, :device_name, :mirrored

  @@layer_inversions = {:Top => :Bottom, :Bottom => :Top}

  def initialize(attrs)
    attrs.each { |k, v| self.send :"#{k}=", v }
  end

  def relative_z
    0
  end

  def layer
    if mirrored
      @@layer_inversions[package[:layer]]
    else
      package[:layer]
    end
  end

end