require 'yaml'
require_relative './models/layout'
require_relative './models/tape'

class LayoutParser
  attr_reader :layout, :gcodes, :board, :yml

  def self.parse(yml, board)
    LayoutParser.new(yml, board).layout
  end

  def initialize(yml, board)
    @yml = yml
    @layout = Layout.new
    # Adding the tapes to the layout
    yml[:tapes].each  do |k, orientations|
      orientations.each { |attrs| initialize_tape k, attrs}
    end
    # Adding the boards to the layout
    layout.board = board
    layout.board_positions = yml[:boards].map &:symbolize_keys
    layout.board_offsets = yml[:boards_offset]
  end

  private

  def initialize_tape(id, attrs)
    attrs = attrs.symbolize_keys
    if attrs[:group].present?
      attrs = yml[:tape_groups][attrs[:group].to_sym].merge attrs
    end
    tape = Tape.new id, attrs
    layout.add_tape tape
  end

end
