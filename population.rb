require 'pp'
require 'ackley'
require 'gaussian_distribution'

class Population
  class Agent <
    Struct.new( 'Agent', :position, :generation )

    def fitness
      Ackley.height( self.position )
    end
  end
  
  attr_reader :agents
  
  def initialize( offspring, evolver )
    gaussian_dist = GaussianDistribution.new( 0.0, 10.0 ) # for seeding population 
    
    @@generation = 1
    @evolver = evolver
    
    @agents = []
    1.upto(offspring) { @agents << Agent.new( gaussian_dist.rand, @@generation ) }
  end
  
  def new_generation
    @@generation += 1
    @agents = @evolver.evolve( @agents )
  end

  def Population.current_generation # class method
    @@generation
  end
  
  def fittest
    @agents.min_by { |agent| agent.fitness }
  end
  
  def average_position
    @agents.inject(0.0) { |sum,a| sum += a.position } / @agents.size
  end
  
  def average_fitness
   @agents.inject(0.0) { |sum,a| sum += a.fitness } / @agents.size 
  end
  
  def size
    @agents.size
  end
end