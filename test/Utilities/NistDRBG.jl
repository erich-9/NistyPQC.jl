module NistDRBG

import ArgCheck: @argcheck
import Base.Iterators: partition
import Nettle
import Random

const (β, κ, σ) = (16, 32, 48)

mutable struct AES256CTR <: Random.AbstractRNG
    key::Vector{UInt8}
    block::Vector{UInt8}

    function AES256CTR(seed::Vector{UInt8})
        @argcheck length(seed) == σ

        rng = new(zeros(UInt8, κ), zeros(UInt8, β))
        (rng.key, rng.block) = partition(seed .⊻ generate(rng, σ), κ)
        rng
    end
end

function Base.rand(rng::AES256CTR, ::Type{UInt8}, n::Int)
    res = generate(rng, n)
    (rng.key, rng.block) = partition(generate(rng, σ), κ)
    res
end

function generate(rng::AES256CTR, n::Int)
    res = Vector{UInt8}()
    while length(res) < n
        rng.block = increment(rng.block)
        append!(res, encrypt(rng.key, rng.block))
    end
    res[1:n]
end

function increment(block)
    reinterpret(UInt8, hton.(ntoh.(reinterpret(UInt128, block)) + [1]))
end

function encrypt(key, block)
    Nettle.encrypt("AES256", :CBC, zeros(UInt8, β), key, block)
end

end # module
