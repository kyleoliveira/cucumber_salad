#!/usr/bin/env ruby
require 'rubygems'
require 'optparse'
require 'json'

options = {}
output_file = 'kuality-kfs-cu-output.json'

opt_parser = OptionParser.new do |opt|

  opt.banner = 'Usage: json_merge.rb [options] <file.json>...'
  opt.separator 'Options:'

  opt.on('-o', '--output FILENAME', "output filename (default: ./#{output_file})") do |filename|
    output_file = filename unless filename.nil?
  end

  opt.on('-v', '--verbose', 'print status info') do
    options[:verbose] = true
  end

  opt.on('-h', '--help', 'help') do
    puts opt
    exit 0
  end
end
opt_parser.parse!
if ARGV.empty?
  puts "ERROR: There are no filenames specified!\n#{opt_parser}"
  exit 1
end

File.open(output_file, 'w') do |out_file|
  out_file.write(ARGV.collect { |in_file| JSON.parse(File.read(in_file)) }.flatten.to_json)
end
