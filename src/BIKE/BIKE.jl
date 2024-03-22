module BIKE

include("Parameters.jl")

import .Parameters: category_parameters

for (category, base_parameters) ∈ category_parameters
    @eval module $category

    export generate_keys, encapsulate_secret, decapsulate_secret

    import ...rng
    import ...Utilities: peel
    import ..Parameters: ℓ
    import ..Parameters: derived_parameters

    import ArgCheck: @argcheck

    const (category_number, r, w, t, nb_iter, τ, _) = $base_parameters
    const (; identifier, r_bytes, d, θ, threshold, lengths) =
        derived_parameters($category, $base_parameters)

    include("Ring.jl")
    include("Sampling.jl")
    include("Hashing.jl")
    include("ErrorDecoding.jl")

    import .Sampling: D̂, Ĥ
    import .Hashing: K̂, L̂

    """
        generate_keys([; seed])

    Return a tuple `(; ek, dk)` consisting of an encapsulation key and the corresponding
    decapsulation key. The length of `ek` will be $(lengths.ek) bytes and the length of `dk`
    $(lengths.dk) bytes.

    For a deterministic result, a `seed` of $ℓ bytes can be provided.
    """
    function generate_keys(;
        seed::Union{Nothing, @NamedTuple{h::U, σ::V}} = nothing,
    ) where {U <: AbstractVector{UInt8}, V <: AbstractVector{UInt8}}
        (h_seed, σ) = if seed !== nothing
            @argcheck length(seed.h) == ℓ
            @argcheck length(seed.σ) == ℓ

            (seed.h, seed.σ)
        else
            Vector{UInt8}.(peel(rand(rng, UInt8, 2ℓ), [ℓ, ℓ]))
        end

        (h₀, h₁) = D̂(h_seed)

        h = h₀^-1 * h₁

        ek = Ring.to_bytes(h)
        dk = [Ring.to_bytes(h₀); Ring.to_bytes(h₁); σ]

        (; ek, dk)
    end

    """
        encapsulate_secret(ek[; m])

    Return a tuple `(; K, c)` consisting of a shared secret `K` and a ciphertext `c` from
    which `K` can be recomputed with the decapsulation key `dk` that corresponds to `ek`.
    The parameter `ek` must be a valid encapsulation key of $(lengths.ek) bytes. The length
    of `K` will be $(lengths.K) bytes and the length of `c` $(lengths.c) bytes.

    For a deterministic result, a plaintext `m` of $ℓ bytes can be provided.
    """
    function encapsulate_secret(
        ek::AbstractVector{UInt8};
        m::AbstractVector{UInt8} = rand(rng, UInt8, ℓ),
    )
        @argcheck length(ek) == lengths.ek
        @argcheck length(m) == ℓ

        h = Ring.Element(ek)

        (e₀, e₁) = Ĥ(m)
        c = [Ring.to_bytes(e₀ + e₁ * h); m .⊻ L̂(e₀, e₁)]
        K = K̂(m, c)

        (; K, c)
    end

    """
        decapsulate_secret(c, dk)

    Return the secret key `K` in case of successful decapsulation. Otherwise implicitly
    reject, i.e. return a deterministic value `K` derived from `c` and `dk`. The parameter
    `c` must have $(lengths.c) bytes and `dk` $(lengths.dk) bytes. Both for successful and
    failed decapsulation, `K` will have a length of $(lengths.K) bytes.
    """
    function decapsulate_secret(c::AbstractVector{UInt8}, dk::AbstractVector{UInt8})
        @argcheck length(c) == lengths.c
        @argcheck length(dk) == lengths.dk

        c₀ = Ring.Element(first(c, r_bytes))
        c₁ = last(c, ℓ)

        (h₀, h₁) = (Ring.Element(x) for x ∈ peel(dk, [r_bytes, r_bytes]))
        σ = last(dk, ℓ)

        ẽ = ErrorDecoding.decode(c₀ * h₀, h₀, h₁)
        m̃ = c₁ .⊻ L̂(ẽ...)

        ẽ == Ĥ(m̃) ? K̂(m̃, c) : K̂(σ, c)
    end

    end # module
end

end # module
