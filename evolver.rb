require 'pp'

require 'evolver_alternatives'

class Evolver
  def initialize( offspring, selection_size, mutator, crossover, selector, variator, demographer, gaussian_mean, gaussian_stddev )
    @offspring       = offspring
    @mutator         = EvolverAlternatives::Mutators.send( mutator, gaussian_mean, gaussian_stddev )
    @crossover       = EvolverAlternatives::Crossovers.send( crossover, offspring )
    @selector        = EvolverAlternatives::Selectors.send( selector, selection_size )
    @variator        = EvolverAlternatives::Variators.send( variator, @mutator, @crossover )
    @demographer     = EvolverAlternatives::Demographers.send( demographer, offspring )
  end
  
  def evolve( agents )
    selected_agents = @selector.call( agents )
    varied_agents   = @variator.call( selected_agents )
    culled_agents   = @demographer.call( varied_agents )
    culled_agents
  end
end