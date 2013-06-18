#!/usr/bin/env ruby

res = {
  "canary-go-shin.herokuapp.com"=>{
    20=>{
      100=>{
        1=> {
          0=> {
            "hz"=>4953,
             "time"=>3598,
             "conn_total"=>893624,
             "conn_successes"=>891847,
             "conn_errors"=>0,
             "conn_timeouts"=>1777,
             "conn_closes"=>37400,
             "http_successes"=>891847,
             "http_errors"=>0,
             "<1"=>1,
             "<5"=>17386,
             "<10"=>60100,
             "<15"=>140805,
             "<20"=>498344,
             "<30"=>160715,
             "<40"=>11640,
             "<50"=>1792,
             "<70"=>498,
             "<100"=>381,
             "<150"=>116,
             "<300"=>48,
             "<500"=>15,
             "<1000"=>5,
             ">=1000"=>1
}}}}}}

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
