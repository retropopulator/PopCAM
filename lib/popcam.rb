#!/usr/bin/env ruby

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

if ARGV[0].blank?
  puts "useage: popcam brd_file"
  exit!
end

# Getting an absolute path to the file
brd_arg = ARGV[0]
base_path = File.expand_path brd_arg.chomp File.extname(brd_arg)
# Loading the yaml layout file
yml = YAML::load_file("#{base_path}.yml").deep_symbolize_keys

# Running the parsers
begin
  board = BrdParser.parse "#{base_path}.brd"
  layout = LayoutParser.parse yml, board
  tapes = layout.tapes
rescue InvalidFileException, BrdParsingException => e
  puts "ERROR! #{e.message}"
  exit
end

# Getting a list of the components on the board
puts "\nBill of Materials"
puts "#{"-"*80}\n\n"
msg = "Misses will not be pick and placed. Add tapes by their Tape IDs to your "
msg += "yml file\nto fix misses.\n\n"
puts msg
puts " Status   Qty   Tape ID #{' '*43} Part(s)\n\n"

# Grouping the components by tape id
grouped = board.components.inject({}){|h, c| (h[c.tape_id] ||= []) << c; h}
# Iterating through the groups
grouped.each do |tape_id, components|
  qty = components.count
  miss = !components.all? do |c|
    (tapes[tape_id]||{}).keys.include? c.rotation
  end
  components_text = components.map do |c|
    tape_group = (yml[:tape_groups].find{|k, tg| tg[:rotation].to_f == c.rotation || (tg[:rotation].to_f + 180) %360 == c.rotation}||[])[0]
    "#{c.name} (#{c.rotation.round} / #{ tape_group || "N/A" })"
  end

  puts [
    " [ #{miss ? "MISS".red : "OK  ".greenish} ]",
    qty.to_s.rjust(3, " "),
    "#{tape_id}".ljust(50, '.'),
    components_text.sort.join(", ")
  ].join("  ")
end

puts ""

GCodeGenerator.new(layout, yml).run.write("#{base_path}.gcode")
