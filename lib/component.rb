require_relative './rotatable'

class Component
  include Rotatable

  attr_accessor :package

  def initialize(attrs)
    attrs.each { |k, v| self.send :"#{k}=", v }
  end

  def relative_z
    0
  end
end