module BIKE

include("Parameters.jl")

import .Parameters: level_parameters

for (level, base_parameters) ∈ level_parameters
    @eval module $level

    export generate_keys, encapsulate_secret, decapsulate_secret

    import ...rng
    import ..Parameters: ℓ
    import ..Parameters: derived_parameters

    import ArgCheck: @argcheck
    import StaticArrays: MVector, StaticVector

    const (level_number, r, w, t, nb_iter, τ, _) = $base_parameters
    const (; identifier, r_bytes, d, θ, threshold) =
        derived_parameters($level, $base_parameters)

    const length_ek = r_bytes
    const length_dk = 2r_bytes + ℓ
    const length_c = r_bytes + ℓ

    include("General.jl")
    include("Ring.jl")
    include("Sampling.jl")
    include("Hashing.jl")
    include("Decoder.jl")

    import .Sampling: D̂, Ĥ
    import .Hashing: K̂, L̂
    import .Decoder: decode

    function generate_keys(;
        seed::Union{Nothing, @NamedTuple{h::U, σ::V}} = nothing,
    ) where {U <: StaticVector{ℓ, UInt8}, V <: StaticVector{ℓ, UInt8}}
        (h_seed, σ) = if seed !== nothing
            (seed.h, seed.σ)
        else
            MVector{ℓ, UInt8}.(Iterators.partition(rand(rng, UInt8, 2ℓ), ℓ))
        end

        (h₀, h₁) = D̂(h_seed)

        h = h₀^-1 * h₁

        ek = Ring.to_bytes(h)
        dk = [Ring.to_bytes(h₀); Ring.to_bytes(h₁); σ]

        (; ek, dk)
    end

    function encapsulate_secret(
        ek::AbstractVector{UInt8};
        m::AbstractVector{UInt8} = rand(rng, UInt8, ℓ),
    )
        @argcheck length(ek) == length_ek
        @argcheck length(m) == ℓ

        h = Ring.Element(ek)

        (e₀, e₁) = Ĥ(m)
        c = [Ring.to_bytes(e₀ + e₁ * h); m .⊻ L̂(e₀, e₁)]
        K = K̂(m, c)

        (; K, c)
    end

    function decapsulate_secret(c::AbstractVector{UInt8}, dk::AbstractVector{UInt8})
        @argcheck length(c) == length_c
        @argcheck length(dk) == length_dk

        c₀ = Ring.Element(c[1:r_bytes])
        c₁ = c[(end - ℓ + 1):end]

        (h₀, h₁) = map(Ring.Element, Iterators.partition(dk[1:(2r_bytes)], r_bytes))
        σ = dk[(end - ℓ + 1):end]

        ẽ = decode(c₀ * h₀, h₀, h₁)
        m̃ = c₁ .⊻ L̂(ẽ...)

        ẽ == Ĥ(m̃) ? K̂(m̃, c) : K̂(σ, c)
    end

    end # module
end

end # module