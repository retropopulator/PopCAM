require_relative './rotatable'
require_relative './component'

class Board
  include Rotatable

  attr_accessor :libraries, :components

  def initialize(opts)
    @opts = opts
  end

  def parse
    f = File.open(@opts[:brd_file])
    @doc = Nokogiri::XML(f)
    parse_libraries
    parse_components
    f.close
    return self
  end

  # Loading the package libraries (each package is a specific type of component)
  # Packages are keyed by [library_name][package_name]
  def parse_libraries
    self.libraries = {}
    @doc.css('libraries library').each do |lib_el|
      # Adding the library
      lib_name = lib_el.attr(:name)
      libraries[lib_name.to_sym] = lib = {}
      # Adding the packages inside the library
      lib_el.css('package').each do |pkg_el|
        # Adding the package
        pkg_name = pkg_el.attr(:name).to_sym
        lib[pkg_name] = {
          name: "#{lib_name}::#{pkg_name}",
          pads: pkg_el.css('smd').map {|el| parse_pads el }
        }
      end
    end
  end

  # Parsing the individual smd pads of the package
  def parse_pads(el)
    attrs = {}
    el.attributes.slice(*%w(x y dx dy layer)).each do |k, v|
      attrs[k.to_sym] = v.value.to_f
    end
    attrs[:rotation] = parse_rot(el)
    return attrs
  end

  def parse_components
    # Loading individual components (things on the board / instances of packages)
    self.components = @doc.css('board elements element').map do |el|
      library = libraries[el.attr("library").to_sym]
      raise "Library not found: #{el.attr("library")}" unless library.present?
      package = library[el.attr("package").to_sym]
      raise "Package not found: #{el.attr("package")}" unless package.present?
      Component.new(
        package: package,
        relative_x: el.attr("x").to_f,
        relative_y: el.attr("y").to_f,
        rotation: parse_rot(el),
        parent: self
      )
    end
  end

  def mark_as_dirty!
    super
    components.each &:mark_as_dirty!
  end

  private

  def parse_rot(el)
    (el.attr("rot")||"R0")[(1..-1)].to_f
  end

end
