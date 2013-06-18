#!/usr/bin/env ruby

filename = ARGV[0]
if filename.nil? || filename == ""
  puts "please specify a filename for the data file to read"
  exit(1)
end

# Really shouldn't use eval :( Maybe change output to JSON?
res = eval File.read(filename)

domain = res.first[0]

def avg(arr = [])
  arr.inject(0.0) { |sum, el| sum + el } / arr.size
end

range_keys = res[domain].first[1].first[1].first[1].first[1].keys.select{|k| k =~ /^(?:<|>=)\d+/}
range_keys << "http_successes"
range_keys << "hz"
puts "dyno_count\trun_number\t" + range_keys.join("\t")

res[domain].first[1].each do |concurrency, results|
  total_values = range_keys.inject({}) {|h, k| h[k] = []; h }
  results.each do |dyno_count, result|
    result.each do |run_number, data|
      range_keys.map{|k| total_values[k] << data[k] }
      puts "#{dyno_count}\t#{run_number}\t" + range_keys.map{|k| data[k]}.join("\t")
    end
    puts "#{dyno_count}\taverage\t" + range_keys.map{|k| avg(total_values[k]).round}.join("\t")
  end
end
