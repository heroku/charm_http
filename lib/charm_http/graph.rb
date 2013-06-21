
class CharmHttp
  class Graph
    def self.graph(filename)
      graph = Graph.new(filename)
      graph.make_req_data
      graph.make_req_chart
      graph.make_dist_charts
    end

    def initialize(filename)
      @filename = filename
      @data = eval(File.read(@filename))
      @headers = @data.keys
      @workers = @data[@headers.first].keys.first
      @concurrencies = @headers.map do |header|
        begin
          @data[header][@workers].keys
        rescue NoMethodError
          puts "ERROR: Inconsistent benchmarking parameters for: #{@headers.join(',')}"
          exit!
        end
      end.flatten.uniq.sort
    end

    def make_req_data
      Dir.mkdir("tmp") rescue nil
      File.open("tmp/data-reqs.ssv", "w") do |ssv|
        ssv.puts "#{@filename}.reqs #{@headers.join(' ')}"
        @concurrencies.each do |c|
          ssv.write "#{@data[@headers.first][@workers][c].keys.first} "

          data = @headers.map do |header|
            hash = @data[header][@workers][c]
            hash = hash[hash.keys.first]

            max = 0
            hash.keys.each do |run|
              if hash[run]["hz"] > max
                max = hash[run]["hz"]
              end
            end
            max
          end

          ssv.puts data.join(' ')
        end
      end

      puts File.read("tmp/data-reqs.ssv")
    end

    def make_dist_data(concurrency)
      num_dynos = @data[@headers.first][@workers][concurrency].keys.first
      Dir.mkdir("tmp") rescue nil
      File.open("tmp/data-dist.ssv", "w") do |ssv|
        ssv.puts "order buckets count"

        all_runs = @data[@headers.first][@workers][concurrency][num_dynos]
        hash1 = all_runs[all_runs.keys.first]
        buckets = hash1.keys.select{|k| k =~ /^(?:<|>=)\d+/ }

        all_values = buckets.inject({}) {|h, k| h[k] = []; h }
        all_runs.each do |run_number, data|
          buckets.each{|k| all_values[k] << data[k] }
        end

        buckets.each_with_index do |k, i|
          ssv.puts "#{i} #{k} #{avg(all_values[k]).round}"
        end

        puts File.read("tmp/data-dist.ssv")
      end
    end

    def make_req_chart
      system("R --vanilla < #{LIB}/charm_http/graph-reqs.r")
    end

    def make_dist_charts
      @concurrencies.each do |c|
        make_dist_data(c)
        num_dynos = @data[@headers.first][@workers][c].keys.first
        output = "#{@filename}.dist.#{num_dynos.to_s.rjust(2, '0')}.dynos.c#{c}.png"
        system("R --vanilla < #{LIB}/charm_http/graph-dist.r --args #{output}")
      end
    end

    def avg(arr = [])
      arr.inject(0.0) { |sum, el| sum + el } / arr.size
    end
  end
end
