require 'pp'

$stdout.sync = true

require 'evolver_alternatives'
require 'evolver'
require 'rubygems'
require 'oyster'

class Runner
  def initialize
    @cli_spec = Oyster.spec do
      name 'runner.rb -- GA / Ackley runner'
      synopsis <<-EOS
        ruby runner.rb [options]
      EOS

      integer :generations,         :default => 10,                   :desc => 'Generations to run. Default 10.'
      integer :offspring,           :default => 10,                   :desc => 'Offspring per generation. Default 10.'
      integer :selection,           :default => 5,                    :desc => 'Selection size. Default 5.'
      string  :mutator,             :default => 'gaussian_addition',  :desc => 'Mutator to use. Default gaussian_addition.'
      string  :crossover,           :default => 'addition',           :desc => 'Crossover to use. Default addition.'
      string  :selector,            :default => 'ranked',             :desc => 'Selector to use. Default ranked.'
      string  :variator,            :default => 'mutate_crossover',   :desc => 'Variation pattern to use. Default mutation_crossover.'
      string  :demographer,         :default => 'parents_retained',   :desc => 'Demography setting to use. Default parents_retained.'
      float   :mean,                :default => 0.0,                  :desc => 'Mean for Gaussian distribution. Default 0.0.'
      float   :std_dev,             :default => 0.5,                  :desc => 'Standard deviation for Gaussian distribution. Default 0.5.'
      integer :runs,                :default => 1,                    :desc => 'How many runs of the GA to make. Default 1.'
      flag    :log,                 :default => false,                :desc => 'Output logs for later analysis. Default false.'
      flag    :debug,               :default => false,                :desc => 'Crushing verbosity. Default false.'

      notes <<
"        Mutators:
          gaussian_addition, gaussian_multiply\n
        Crossovers:
          addition, average, alternate_digits\n
        Selectors:
          ranked, proportional\n
        Variators:
          mutate_crossover, crossover_mutate, mutate_only, crossover_only\n
        Demographers:
          parents_retained, parents_culled\n"

      author 'Jacques Chester 20304893'
    end
  end
  
  def run
    begin
      opts = @cli_spec.parse

      @generations         = opts[:generations]
      @offspring           = opts[:offspring]
      @selection_size      = opts[:selection]
      @mutator             = opts[:mutator]
      @crossover           = opts[:crossover]
      @selector            = opts[:selector]
      @variator            = opts[:variator]
      @demographer         = opts[:demographer]
      @gaussian_mean       = opts[:mean]
      @gaussian_stddev     = opts[:std_dev]
      @runs                = opts[:runs]
      @log                 = opts[:log]
      @debug               = opts[:debug]
      
      @evolver             = Evolver.new( @offspring, @selection_size, @mutator, @crossover, @selector, @variator, @demographer, @gaussian_mean, @gaussian_stddev )
      @population          = Population.new( @offspring, @evolver )

      @initial_best        = @population.fittest

      @timestamp           = Time.now.strftime('%s')


      1.upto(@runs) do |run|
        logfile = nil
        if @log
          lfname = "logs/ga_#{@timestamp}_run_#{run}.csv"
          logfile = File.open( lfname, 'a' )
          logfile << header
          puts "Logging to #{lfname}"
        else
          puts header
        end

        1.upto(@generations) do |iter|
          @population.new_generation
          @new_fittest = @population.fittest

          if @new_fittest.fitness == 0.0
            footer 'terminated early, found known global minimum.'
            exit
          end

          if @log
            logfile << log_line( iter )
          else
            print status_line( iter )
          end
          trap("INT") { puts footer("interrupted on #{iter}"); exit }
        end
        
        if @log
          logfile << footer('complete')
          logfile.close
        end
      end

      puts footer('complete') unless @log
    rescue Oyster::HelpRendered
      exit
    end
  end
  

  def status_line( iteration )
    avg_position = @population.average_position
    avg_fitness = @population.average_fitness
    status_line = "        %#{@generations.to_s.length}u            %2.4f\t\t %2.4f\t\t\t%2.4f\t\t%2.4f" % [iteration,  @new_fittest.position, @new_fittest.fitness, avg_position, avg_fitness]
    @debug ? status_line + "\n" : status_line + "\r"
  end
  
  def log_line( iteration )
    avg_position = @population.average_position
    avg_fitness = @population.average_fitness
    
    "\n#{iteration},#{@new_fittest.position},#{@new_fittest.fitness},#{avg_position},#{avg_fitness}"
  end
  
  def header
"    # Commencing Genetic Algorithm optimisation of 2D Ackley's function at #{Time.now}
    # Generations: #{@generations}
    # Offspring per Generation: #{@offspring}
    # Parents per Generation: #{@selection_size}
    # Mutator: #{@mutator}
    # Crossover: #{@crossover}
    # Selector: #{@selector}
    # Variator: #{@variator}
    # Demographer: #{@demographer}
    # Gaussian mean/stddev: #{@gaussian_mean} / #{@gaussian_stddev}
    # Global minimum at: 0.0
    # Initial best position: #{@initial_best.position}
    # Initial best fitness: #{@initial_best.fitness}
    #{'# DEBUG ON' if @debug}
    # Generation    Current Best Pos    Current Best Fitn     Avg Position    Avg Fitness
    # ------------------------------------------------------------------------------------------------------"
  end
  
  def footer( end_status )
    "\n    # ------------------------------------------------------------------------------------------------------\n# Run #{end_status}.\n# #{Time.now}\n"
  end
end

Runner.new.run