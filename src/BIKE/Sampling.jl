module Sampling

import ..r, ..d, ..t
import ..Ring

import Base.Iterators: partition
import Random: AbstractRNG, bitrand
import SHAKE: SHAKE256RNG

# In order to reproduce the KAT, I'm not following the specification here.

function D̂(seed)
    rng = SHAKE256RNG(seed)
    [Ring.Element(random_positions(rng, r, d)) for _ ∈ 1:2]
end

function Ĥ(seed)
    positions = random_positions(SHAKE256RNG(seed), 2r, t)
    map(Ring.Element, partition(positions, r))
end

function random_positions(rng, len, choices)
    positions = falses(len)
    s = reinterpret(UInt32, rand(rng, UInt8, choices << 2))
    @inbounds for i ∈ choices:-1:1
        j = i + (Int64(len - i + 1) * s[choices - i + 1]) >> 32
        positions[positions[j] ? i : j] = true
    end
    positions
end

Base.rand(rng::AbstractRNG, ::Type{Ring.Element}) = Ring.Element(bitrand(rng, r))

end # module
