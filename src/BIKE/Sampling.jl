module Sampling

import ..r, ..d, ..t
import ..Ring

import Base.Iterators: partition
import CryptographicHashFunctions: digest!, shake256
import Random: AbstractRNG, bitrand

# In order to reproduce the KAT, I'm not following the specification here.

function D̂(seed)
    xof = shake256(seed)
    [Ring.Element(random_positions(xof, r, d)) for _ ∈ 1:2]
end

function Ĥ(seed)
    positions = random_positions(shake256(seed), 2r, t)
    map(Ring.Element, partition(positions, r))
end

function random_positions(xof, len, choices)
    positions = falses(len)
    s = reinterpret(UInt32, digest!(xof, choices << 2))
    for i ∈ choices:-1:1
        j = i + (Int64(len - i + 1) * s[choices - i + 1]) >> 32
        positions[positions[j] ? i : j] = true
    end
    positions
end

Base.rand(rng::AbstractRNG, ::Type{Ring.Element}) = Ring.Element(bitrand(rng, r))

end # module
