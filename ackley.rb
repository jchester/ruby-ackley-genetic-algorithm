module Ackley
  MIN = -30
  MAX = 30
  N =   20
  DOUBLE_PI = 2*Math::PI # Performance; calculate 2π once only. 

  def height(x)
    quad_sum = N * x * x # performance; * operator faster than ** operator.
    cos_sum = N * Math.cos(DOUBLE_PI * x)

    first_term = Math.exp(-0.2 * Math.sqrt( (quad_sum / N) ))
    second_term = Math.exp( (cos_sum / N) )

    Math::E - (20 * first_term) - second_term + 20      
  end

  def feasible?( position )
    position.between?( MIN, MAX )
  end

  module_function :height, :feasible?
end

