# Test TraceC and TraceR

using Turing
using Distributions

import Turing: Trace, TraceR, TraceC, current_trace, fork, fork2, randr

function f2()
  t = TArray(Int, 1);
  t[1] = 0;
  while true
    rand(current_trace(), Normal(0,1))
    produce(t[1])
    rand(current_trace(), Normal(0,1))
    t[1] = 1 + t[1]
  end
end

# Test task copy version of trace
t = TraceC(f2)

consume(t); consume(t)
a = fork(t);
consume(a); consume(a)

Base.@assert consume(t) == 2
Base.@assert consume(a) == 4


# Test replaying version of trace
t = TraceR(f2)

consume(t); consume(t)
a = fork(t);
consume(a); consume(a)

Base.@assert consume(t) == 2
Base.@assert consume(a) == 4

a2 = fork(t)
Base.@assert length(a2.randomness) == 5
Base.@assert t.randomness == a2.randomness
Base.@assert t.index == a2.index
