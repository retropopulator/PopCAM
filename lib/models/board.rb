require_relative './rotatable'

class Board
  include Rotatable

  attr_accessor :libraries, :components

  def mark_as_dirty!
    super
    components.each &:mark_as_dirty!
  end

end
