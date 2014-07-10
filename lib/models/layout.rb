require_relative './offset'

class Layout
  attr_accessor :board, :tapes, :board_positions

  def initialize
    @tapes = {}
  end

  def add_tape(tape)
    (@tapes[tape.id] ||= {})[tape.rotation] = tape
  end

  def each_board_position
    board_positions.each_with_index do |board_position, index|
      # Repositioning the board for this board_position
      board.set_position! board_position
      # Reuse the same board object for each position to reduce GC / memory
      # footprint.
      yield board, index
    end
  end

  def board_offsets=(offsets)
    board.parent = Offset.new offsets
  end
end
