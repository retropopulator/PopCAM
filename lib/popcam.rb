#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'active_support/all'
require 'rubygems'
require 'ap'

require_relative './board'
require_relative './gcode_generator'
require_relative './invalid_file_exception'
require_relative './brd_parsing_exception'

base_name = ARGV[0] || "./examples/HeartSparkBar_V2p0"
opts = {
  brd_file: "#{base_name}.brd",
  layout_file: "#{base_name}.yml"
}

begin
  board = Board.new(opts).parse
rescue InvalidFileException, BrdParsingException => e
  puts "ERROR! #{e.message}"
  exit!
end

opts[:board] = board

# Getting a list of the components on the board
puts "Component List:"
board.components.map{|c| (c.package||{})[:name]}.uniq.each do |name|
  puts "*  #{name}"
end

puts "\n\n"

# Getting the positions of all 0805 resistor smd pads
# resistors = board.components.select do |c|
#   c[:package][:name] == "wuerth-elektronik::0805"
# end
# resistor_pads = []
# resistors.each do |c|
#   c[:package][:pads].each do |pad|
#     pad = pad.clone
#     # TODO: pad x and pad y need to be multiplied by cos r and sin r
#     pad[:x] += c[:x]
#     pad[:y] += c[:y]
#     resistor_pads.push pad
#   end
# end
# ap resistor_pads

gcode_generator = GCodeGenerator.new(opts)

gcode_generator.run.write("#{base_name}.gcode")
# ap gcode_generator.gcodes
