require 'pp'

require 'ackley'
require 'gaussian_distribution'
require 'population'

require 'rubygems'
require 'backports' # add the sample method to Array

module EvolverAlternatives
  module Mutators
    def gaussian_addition( mean, std_dev )
      gauss_dist = GaussianDistribution.new( mean, std_dev )
      lambda do |agents|
        agents.each { |a| a.position =  a.position + gauss_dist.rand }
      end
    end

    def gaussian_multiply( mean, std_dev )
      gauss_dist = GaussianDistribution.new( mean, std_dev )
      lambda do |agents|
        agents.each { |a| a.position = a.position * gauss_dist.rand }
      end
    end
    
    module_function :gaussian_addition, :gaussian_multiply
  end
  
  module Crossovers
    def addition( offspring )
      lambda do |agents|
        new_agents = []
        
        until new_agents.size == offspring
          agent_left = agents.sample
          agent_right = agents.sample

          new_position = agent_left.position + agent_right.position
          new_agent = Population::Agent.new( new_position, Population.current_generation )
          new_agents << new_agent if Ackley.feasible?( new_agent.position )
        end

        agents + new_agents      
      end
    end
    
    def average( offspring )
      lambda do |agents|
        new_agents = []
        until new_agents.size == offspring
          agent_left = agents.sample
          agent_right = agents.sample

          new_position = agent_left.position + agent_right.position / 2
          new_agent = Population::Agent.new( new_position, Population.current_generation )
          new_agents << new_agent if Ackley.feasible?( new_agent.position )
        end

        agents + new_agents
      end
    end
    
    def alternate_digits( offspring )
      lambda do |agents|
        new_agents = []
        until new_agents.size == offspring
          left_pos = agents.sample.position.to_s
          right_pos = agents.sample.position.to_s

          # account for - symbol by adding blank space to front of non-negative numbers
          left_pos  = ' ' + left_pos  if left_pos.to_f  > 0.0
          right_pos = ' ' + right_pos if right_pos.to_f > 0.0
          
          new_pos_string = ''
          flip_flop = true
          0.upto(10) do |digit| # 10 digits ought to be enough precision for anybody
            new_pos_string += ( flip_flop ? left_pos[digit].chr : right_pos[digit].chr )
            flip_flop = !flip_flop
          end
          
          new_pos_string.gsub!( /\.\./, '') # remove surplus decimal point
          new_position = Float( new_pos_string )
          new_agents << Population::Agent.new( new_position, Population.current_generation ) if Ackley.feasible?( new_position )
        end

        agents + new_agents
      end
    end
    
    module_function :addition, :average, :alternate_digits
  end
  
  module Selectors
    def ranked( number_to_select )
      lambda do |candidates|
        candidates.sort { |x,y| x.fitness <=> y.fitness }[0..number_to_select]
      end
    end
    
    def proportional( number_to_select )
      lambda do |candidates|
        ranked = candidates.sort { |x,y| x.fitness <=> y.fitness }[0..number_to_select]
        total_fitness = ranked.inject(0.0) { |sum,c| sum += c.fitness }
        proportional = []
        ranked.each do |c|
          insert_proportion = ( c.fitness / total_fitness ) * number_to_select
          proportional << [c]*insert_proportion # amazing how much faster this is than my naive initial 0.upto(fitness) version!
        end
      end
    end
    
    module_function :ranked, :proportional
  end
  
  module Variators
    def mutate_crossover( mutator, crossover )
      lambda do |agents|
        mutator.call( agents )
        crossover.call( agents )
      end
    end
    
    def crossover_mutate( mutator, crossover )
      lambda do |agents|
        new_agents = crossover.call( agents )
        mutator.call( new_agents )
      end
    end
    
    def mutate_only( mutator, crossover )
      lambda do |agents|
        mutator.call( agents )
      end
    end
    
    def crossover_only( mutator, crossover )
      lambda do |agents|
        crossover.call( agents )
      end
    end
    
    module_function :mutate_crossover, :crossover_mutate, :mutate_only, :crossover_only
  end
  
  module Demographers
    def parents_retained( offspring )
      lambda do |agents|
        culled = agents.select { |a| a.generation >= ( Population.current_generation - 1 ) } # cull grandparents
        culled.sample( offspring )
      end
    end
    
    def parents_culled( offspring )
      lambda do |agents|
        culled = agents.select { |a| a.generation == Population.current_generation }
        culled.sample( offspring )
      end
    end
    
    module_function :parents_retained, :parents_culled
  end
end