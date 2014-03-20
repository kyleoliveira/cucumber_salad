#!/usr/bin/ruby
require 'rubygems'
require 'json'

kuality_dir = '$HOME/kuality'
number_of_lists = 10

class Array
  def in_groups(num_groups)
    return [] if num_groups == 0
    slice_size = (self.size/Float(num_groups)).ceil
    self.each_slice(slice_size).to_a
  end
end

number_of_lists = 10


tags = []
begin
  file = File.new("#{File.dirname(File.readlink(__FILE__))}/known_tags.csv", 'r')
  while (line = file.gets)
    tags << line.chomp
  end
  file.close
rescue => err
  puts "Exception: #{err}"
  err
end

puts "Read in these tags:\n#{tags}"

tags = Hash[
  tags.map! do |tag|
    find_result = `find #{kuality_dir}/kuality-kfs-cu/features -name "*feature" -exec grep -H #{tag} {} \\;`
    [ tag, find_result.split("\n").collect {|s| s.split(' ')[1] }.uniq ]
  end
]

puts "Converted to these lists:\n#{tags}"

count = 0
lists = Hash.new
tags.each do |tag, vals|
  vals.in_groups(number_of_lists).each do |s|
    count += 1
    lists[count].nil? ? lists.merge!({count => s.to_a}) : lists[count].push(s.to_a).flatten!
  end
  count = 0
end
puts "Here are our #{number_of_lists} lists:\n#{lists}"

# Now create threads that run each of these lists in parallel, excluding @nightly-jobs tests
threads = []
lists.each do |id, list|
  threads[id] = spawn "cucumber #{kuality_dir}/kuality-kfs-cu/features" <<
                              ' -p master --tags ~@nightly-jobs' <<
                               list.map { |t| " --tags #{t}" }.join('') <<
                              " --format json -o kuality-kfs-cu-output.split#{format('%#02d', id)}.json"
end
Process.waitall

# Now run all nightly-jobs tests in serial
#number_of_lists += 1
#cmd = 'cucumber /Users/kco26/RubymineProjects/kuality/kuality-kfs-cu/features' <<
#              ' -p master --tags @nightly-jobs --format json' <<
#              " -o kuality-kfs-cu-output.split#{number_of_lists.format('%2d')}.json"
#Process.wait(spawn cmd)

# Merge all the results
results = []
(number_of_lists + 1).times do |x|
  results << JSON.parse(File.read("kuality-kfs-cu-output.split#{format('%#02d', number_of_lists)}.json"))
end

final = []
results.first.each_with_index do |ah,i|
  results[1..(results.length - 1)].each do |b|
    unless (bh = b[i])
      bh = {}
      puts "seems b has no #{i} key, merging skipped"
    end

    final << ah.merge(bh).inject({}) do |f, (k,v)|
      if v.is_a?(String)
        if v =~ /\A\d+\.\d+\Z/
          v = v.to_f
        elsif v =~ /\A\d+\Z/
          v = v.to_i
        end
      end
      f.update k => v
    end
  end
end

# Merge complete, let's output to a final file...
File.open('kuality-kfs-cu-output.json', 'w') do |f|
  f.write(final.to_json)
end

# Done!
