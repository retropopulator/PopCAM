require 'rubygems'
require 'nokogiri'
require 'active_support/all'
require 'rubygems'
require 'ap'

require_relative './brd_parser'
require_relative './layout_parser'
require_relative './gcode_generator'
require_relative './exceptions/invalid_file_exception'
require_relative './exceptions/brd_parsing_exception'

class PopCAM

  attr_reader :board, :layout, :gcode_generator, :yml

  delegate :run, :gcodes, to: :gcode_generator
  delegate :tapes, to: :layout

  def initialize(input_path)
    # Getting an absolute path to the file
    @base_path = File.expand_path input_path.chomp File.extname(input_path)
    # Loading the yaml layout file
    @yml = YAML::load_file("#{@base_path}.yml").deep_symbolize_keys

    # Running the parsers
    @board = BrdParser.parse "#{@base_path}.brd"
    @layout = LayoutParser.parse yml, board
    @gcode_generator = GCodeGenerator.new(layout, yml)
  end

  def process!
    run.write("#{@base_path}.gcode")
  end

end
