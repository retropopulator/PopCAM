require_relative './rotatable'

class Component
  include Rotatable

  attr_accessor :package, :device_name

  def initialize(attrs)
    attrs.each { |k, v| self.send :"#{k}=", v }
  end

  def relative_z
    0
  end
end