runs = 20
generations = 50
offspring = [20, 100, 1000]
mutators = [ 'gaussian_addition', 'gaussian_multiply' ]
crossovers = [ 'alternate_digits' ] # 'addition', 'average' ignored because they lead to runaway loops ending in infeasible populations
selectors = [ 'ranked', 'proportional' ]
selection_percent = [ 10, 50, 80 ]
variators = [ 'mutate_crossover', 'crossover_mutate' ] # ignore crossover-only / mutate-only, they lead to exciting crashes in some scenarios
demographers = [ 'parents_retained', 'parents_culled']
std_dev = [ 0.5, 10.0 ]

total_experiments = offspring.size * mutators.size * crossovers.size * selectors.size * selection_percent.size * variators.size * demographers.size * std_dev.size
experiment_number = 1
puts "Total experiments: #{total_experiments}"
experiment_number = 1
offspring.each do |o|
  mutators.each do |m|
    crossovers.each do |c|
      selectors.each do |s|
        variators.each do |v|
          demographers.each do |d|
            std_dev.each do |sd|
              selection_percent.each do |sp|
                begin
                  runstr = "ruby runner.rb -l -o #{o} -m #{m} -c #{c} -S #{s} -s #{o/sp} -v #{v} -d #{d} --std_dev #{sd} -g #{generations} -r #{runs}"
                  puts "#{experiment_number} / #{total_experiments}: #{runstr}"
                  `#{runstr}`
                  experiment_number += 1
                rescue # Just keep going
                  puts "\nAt #{experiment_number}, blew up on: #{runstr}"
                  experiment_number += 1
                  next
                end
              end
            end
          end
        end
      end
    end
  end
end