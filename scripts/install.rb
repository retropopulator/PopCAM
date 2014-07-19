#!/usr/bin/env ruby

dir = File.expand_path(File.dirname File.dirname(__FILE__))
done = "[ DONE ]"

puts "Running bundle install.."
`cd #{dir}&bundle install`
puts "Running bundle install.. #{done}"

puts "Adding symlink.."
`rm /usr/local/bin/popcam`
`ln -s #{File.join dir, "lib", "popcam.rb"} /usr/local/bin/popcam`
puts "Adding symlink.. #{done}"

