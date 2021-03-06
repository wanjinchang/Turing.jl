abstract InferenceAlgorithm{P}
abstract Sampler{T<:InferenceAlgorithm}
abstract GradientSampler{T} <: Sampler{T}

doc"""
    ParticleSampler{T}

Generic interface for implementing inference algorithms.
An implementation of an algorithm should include the following:

1. A type specifying the algorithm and its parameters, derived from InferenceAlgorithm
2. A method of `run` function that produces results of inference. TODO: specify the format of this output
3. Methods for modelling functions specified in this file. This is where actual inference happens.

Turing translates models to thunks that call the modelling functions below at specified points.
Their dispatch is based on the value of a global variable `sampler`.
To include a new inference algorithm implement the requirements mentioned above in a separate file,
then include that file at the end of this one.
"""
type ParticleSampler{T} <: Sampler{T}
  alg ::  T
  particles :: ParticleContainer
  model :: Function
  ParticleSampler(m :: Function, a :: T) = (s = new(); s.alg = a; s.model = m; s)
end

# Concrete algorithm implementations.
include("support/resample.jl")
include("support/transform.jl")
include("hmc.jl")
include("is.jl")
include("smc.jl")
include("pgibbs.jl")

# Fallback functions
Base.run(spl :: Sampler) = error("[sample]: unmanaged inference algorithm: $(typeof(spl))")

assume(spl, distr :: Distribution) =
  error("[assume]: unmanaged inference algorithm: $(typeof(spl))")

observe(spl, weight :: Float64) =
  error("[observe]: unmanaged inference algorithm: $(typeof(spl))")

predict(spl, var_name :: Symbol, value) =
  error("[predict]: unmanaged inference algorithm: $(typeof(spl))")

# Default functions
function sample(model::Function, alg :: InferenceAlgorithm)
  global sampler = ParticleSampler{typeof(alg)}(model, alg);
  Base.run(sampler)
end

assume(spl :: Sampler, d :: Distribution, p)  = rand( current_trace(), d )
observe(spl :: Sampler, d :: Distribution, value) = produce(logpdf(d, value))

function predict(spl :: Sampler, v_name :: Symbol, value)
  task = current_task()
  if haskey(task.storage, :turing_predicts)
    predicts = task.storage[:turing_predicts]
  else
    predicts = Dict{Symbol,Any}()
  end
  predicts[v_name] = value
  task.storage[:turing_predicts] = predicts
end
