require 'rubygems'
require 'nokogiri'
require 'ap'
require 'active_support/all'

source = ARGV[0] || "./examples/RisheaHS_V0p1.xml"

f = File.open(source)
doc = Nokogiri::XML(f)


# Loading the package libraries (each package is a specific type of component)
# Packages are keyed by [library_name][package_name]
libraries = {}
doc.css('libraries library').each do |lib_el|
  # Adding the library
  lib_name = lib_el.attr(:name)
  libraries[lib_name.to_sym] = lib = {}
  # Adding the packages inside the library
  lib_el.css('package').each do |pkg_el|
    # Parsing the individual smd pads of the package
    pads = pkg_el.css('smd').map do |el|
      attrs = {}
      el.attributes.slice(*%w(x y dx dy layer)).each do |k, v|
        attrs[k.to_sym] = v.value.to_f
      end
      attrs[:rotation] = (el.attr("rot")||"R0")[(1..-1)].to_f
      attrs
    end
    # Adding the package
    pkg_name = pkg_el.attr(:name).to_sym
    lib[pkg_name] = {
      name: "#{lib_name}::#{pkg_name}",
      pads: pads
    }
  end
end

# Loading individual components (things on the board / instances of packages)
components = doc.css('board elements element').map do |el|
  library = libraries[el.attr("library").to_sym]
  raise "Library not found: #{el.attr("library")}" unless library.present?
  package = library[el.attr("package").to_sym]
  raise "Package not found: #{el.attr("package")}" unless package.present?
  {
    package: package,
    x: el.attr("x").to_f,
    y: el.attr("y").to_f,
    rotation: (el.attr("rot")||"R0")[(1..-1)].to_f
  }
end

f.close

# Getting a list of the components on the board
puts "Please order the component strips as follows:"
components.map{|c| (c[:package]||{})[:name]}.uniq.each_with_index do |name, i|
  puts "#{i}) #{name}"
end

# Getting the positions of all 0805 resistor smd pads
# resistors = components.select do |c|
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

tape_spacing = 3 # mm
spacing_between_tapes = 12 # mm
tape_offset = {x: 12, y: 20, z: 10}
part_offset = {x: 100, y: 100, z: 7}

gcodes = []
package_counts = {}
y_offset = tape_offset[:y] - spacing_between_tapes
components.sort_by {|c| c[:package][:name]}.each do |c|
  next if c[:package].blank?
  pkg_name = c[:package][:name]
  i = (package_counts[pkg_name] ||= 0)
  y_offset += spacing_between_tapes if i == 0
  package_counts[pkg_name] += 1
  gcodes << "# #{pkg_name} ##{i}"
  # Pick up the component
  gcodes << "G1 X#{i*tape_spacing + tape_offset[:x]} Y#{y_offset}"
  gcodes << "G1 Z#{tape_offset[:z]}"
  gcodes << "G1 Z0"
  # Move the component into position
  gcodes << "G1 X#{c[:x] + part_offset[:x]} Y#{c[:y] + part_offset[:y]}"
  # Place the component
  gcodes << "G1 Z#{part_offset[:z]}"
end

ap gcodes
