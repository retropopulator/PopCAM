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

if ARGV[0].blank?
  puts "useage: popcam brd_file"
  exit!
end

# Getting an absolute path to the file
brd_arg = ARGV[0]
base_path = File.expand_path brd_arg.chomp File.extname(brd_arg)
opts = {
  brd_file: "#{base_path}.brd",
  layout_file: "#{base_path}.yml"
}

begin
  board = Board.new(opts).parse
rescue InvalidFileException, BrdParsingException => e
  puts "ERROR! #{e.message}"
  exit!
end

opts[:board] = board

# Getting a list of the components on the board
puts "\nBill of Materials"
puts "#{"-"*80}\n\n"
puts "Qty  Part"
board.components.map{|c| c.tape_id}.uniq.each do |name|
  qty = board.components.select{|c| c.tape_id == name}.count
  puts "#{qty.to_s.rjust 3, " "}  #{name}"
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

puts "Loading tapes\n#{"-"*80}\n"
msg = "Misses will not be pick and placed. "
msg += "Add tapes to your yml file to fix misses.\n\n"
puts msg

gcode_generator = GCodeGenerator.new(opts)

gcode_generator.run.write("#{base_path}.gcode")
# ap gcode_generator.gcodes
