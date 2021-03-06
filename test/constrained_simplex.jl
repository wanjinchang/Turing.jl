using Distributions
using Turing
using Base.Test

obs = [1,2,1,2,2,2,2,2,2,2]

@model constrained_simplex_test begin
  @assume ps ~ Dirichlet(2, 3)
  for i = 1:length(obs)
    @observe obs[i] ~ Categorical(ps)
  end
  @predict ps
end

chain = sample(constrained_simplex_test, HMC(2000, 0.75, 5))
println(mean(chain[:ps]))

@test_approx_eq_eps mean(chain[:ps]) [5/16 11/16] 0.01
