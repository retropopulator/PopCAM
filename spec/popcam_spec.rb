require_relative '../lib/popcam'

describe PopCAM do

  describe "#run" do
    before :each do
      path = File.join(
        File.dirname(__FILE__), "..", "examples", "MoodSpark_V1p0.brd"
      )
      @pop_cam = PopCAM.new(path)
      @pop_cam.run
      @gcodes = @pop_cam.gcodes
    end

    def gcodes_for(comment)
      comment = "\n; #{comment}"
      # find the gcodes from the line the comment is on to the next comment
      begin
        first =  1 + @gcodes.index {|gcode| gcode.match(comment) != nil}
      rescue
        raise "Cannot find #{comment.gsub(/[\n;]/, "").strip} in GCode"
      end
      length_including_next = @gcodes[first..-1].index do |gcode|
        gcode.match(/$\n?\n?[;] ?/) != nil
      end
      last = length_including_next ? first + length_including_next - 1 : -1
      @gcodes[first..last]
    end

    def pick_coords(comment)
      gcode_line = gcodes_for(comment)[0]
      h = {}
      gcode_line.gsub(/G1|F\d+/, "").strip.split(" ").each do |s|
        h[s[0].downcase.to_sym] = s[1..-1].to_f
      end
      return h
    end

    it "should pick components from the strip with the correct increment" do
      x = (0..1).map {|i| pick_coords("tanjent::0603_TANJ::1k @ 90.0° ##{i}")[:x]}
      expect(x[0]).to eq 0
      expect(x[1]).to eq 4
    end

    it "should pick components from subsequent strips with the correct spacing" do
      ap @gcodes
      y = [
        "tanjent::0603_TANJ::1k @ 90.0° #0",
        "tanjent::0603_TANJ::10k @ 90.0° #0"
      ].map {|comment| pick_coords(comment)[:y]}
      expect(y[0]).to eq 0
      expect(y[1]).to eq 10
    end

  end
end
