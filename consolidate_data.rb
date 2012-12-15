require 'pp'
require 'set'
require 'rubygems'
require 'fastercsv'
require 'narray'

FIXED_WIDTH_FONT = '/Library/Fonts/Andale Mono.ttf'

experiment_ids = Set.new

Dir.glob('logs/*').each do |filename|
  experiment_ids << filename.match(/\d+/)[0]

end

all_current_best_positions = {}
all_current_best_fitnesses = {}
all_current_avg_positions  = {}
all_current_avg_fitnesses  = {}

experiment_ids.each do |exp_id|
  begin
    runs = []
    current_best_positions = NMatrix.float( 20, 50 ) # twenty columns for runs, fifty rows for generations. 
    # current_best_fitnesses = NMatrix.float( 20, 50 )
    current_avg_positions  = NMatrix.float( 20, 50 )
    # current_avg_fitnesses  = NMatrix.float( 20, 50 )

    metadata = {}
    metadata_file = File.open( "logs/ga_#{exp_id}_run_1.csv", 'r' ).read # use this to get configuration of experiment
    
    float_regex = '[-+]?[0-9]*\.?[0-9]+'
    
    metadata[:generations] = metadata_file.match(/Generations: (\d+)/)[1]
    metadata[:offspring]   = metadata_file.match(/Offspring per Generation: (\d+)/)[1]
    metadata[:parents]     = metadata_file.match(/Parents per Generation: (\d+)/)[1]
    metadata[:selector]    = metadata_file.match(/Selector: (\w+)/)[1]
    metadata[:mutator]     = metadata_file.match(/Mutator: (\w+)/)[1]
    metadata[:crossover]   = metadata_file.match(/Crossover: (\w+)/)[1]
    metadata[:variator]    = metadata_file.match(/Variator: (\w+)/)[1]
    metadata[:demographer] = metadata_file.match(/Demographer: (\w+)/)[1]
    metadata[:gauss]       = metadata_file.match(/mean\/stddev: (#{float_regex} \/ #{float_regex})/)[1]
    
    1.upto(20) do |run|
      csv_file = File.open( "logs/ga_#{exp_id}_run_#{run}.csv", 'r' ) # use this to extract data
    
      csv_string = ''
    
      csv_file.each do |line|
        csv_string << line unless line.match(/#/) or line.match(/^\s+$/)
      end
      csv_file.close

      rundata = FasterCSV.parse( csv_string )
      rundata.each do |row|
        run_index = run-1
        row_index = row[0].to_i - 1

        current_best_positions[run_index,row_index] = row[1].to_f # NMatrix is addressed in column,row order.
        current_avg_positions[run_index,row_index]  = row[3].to_f
      end
    end

    all_current_best_positions[exp_id] = [current_best_positions, metadata]
    all_current_avg_positions[exp_id]  = [current_avg_positions, metadata]
    
  rescue Errno::ENOENT
    puts "Experiment #{exp_id} has an incomplete set"
    next
  end
end

# Turn into gold
# Current best position
curr_best_pos_data = File.open( 'data/all_current_best_positions.data', 'a')
dat_str = ''
0.upto(49) do |row|
  all_current_best_positions.each do |exp_id,experiment|
    data = experiment[0]
    metadata = experiment[1]
    dat_str += "#{data[true,row].mean}\t#{data[true,row].stddev}\t"
  end
  dat_str += "\n"
end
curr_best_pos_data << dat_str
curr_best_pos_data.close

# Current average position

curr_avg_pos_data = File.open( 'data/all_current_avg_positions.data', 'a')
dat_str = ''
0.upto(49) do |row|
  all_current_avg_positions.each do |exp_id,experiment|
    data = experiment[0]
    metadata = experiment[1]
    dat_str += "#{data[true,row].mean}\t#{data[true,row].stddev}\t"
  end
  dat_str += "\n"
end
curr_avg_pos_data << dat_str
curr_avg_pos_data.close

# Make pretty pictures
curr_avg_pos_plot = File.open( 'data/combined.plot', 'a')
plt_str =  "set nokey\n"
plt_str =  "unset bars\n"
plt_str += "set term png font \"#{FIXED_WIDTH_FONT}\" 11 "
plt_str += "size 1000,1000\n"
col = 1
all_current_avg_positions.each do |exp_id,experiment|
  data = experiment[0]
  metadata = experiment[1]
  
  plt_str += "set output 'graphs/#{exp_id}.png'\n"
  plt_str += "set multiplot layout 2,1 title "
  plt_str += "\"Experiment #{exp_id}\\n"
  plt_str += "Generations: #{metadata[:generations]}   "
  plt_str += "Offspring: #{metadata[:offspring]}   "
  plt_str += "Parents: #{metadata[:parents]}   "
  plt_str += "Gaussian: #{metadata[:gauss]}\\n"
  plt_str += "Selector: #{metadata[:selector]}   "
  plt_str += "Mutator: #{metadata[:mutator]}   "
  plt_str += "Crossover: #{metadata[:crossover]}\\n"
  plt_str += "Variator: #{metadata[:variator]}   "
  plt_str += "Demographer: #{metadata[:demographer]}\"\n"

  plt_str += "plot [0:49] 'data/all_current_best_positions.data' using :#{col}:#{col+1} with yerrorbars title 'Best individual positions' linestyle 1\n"
  plt_str += "plot [0:49] 'data/all_current_avg_positions.data' using :#{col}:#{col+1} with yerrorbars title 'Population average position' linestyle 2\n"
  plt_str += "unset multiplot\n"
  col+=2
end
curr_avg_pos_plot << plt_str
curr_avg_pos_plot.close