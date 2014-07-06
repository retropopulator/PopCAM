require_relative './rotatable'
require_relative './tape'

class Component
  include Rotatable

  attr_accessor :package, :device_name, :mirrored, :name

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

  def tape_id
    "#{device_name}::#{rotation.round}deg".to_sym
  end

end