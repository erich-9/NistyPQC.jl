module McEliece

include("Parameters.jl")
include("Matrices.jl")

import .Parameters: category_parameters

for (category, base_parameters) ∈ category_parameters
    @eval module $category

    export generate_keys, encapsulate_secret, decapsulate_secret

    import ...rng
    import ...Utilities: peel, bits2bytes, bytes2bits
    import ..Parameters: σ₁, σ₂
    import ..Parameters: derived_parameters

    import ArgCheck: @argcheck
    import Random: AbstractRNG

    const (category_number, n, f, F, fast_variant) = $base_parameters
    const (; identifier, m, t, k, q, τ, μ, ν, lengths) =
        derived_parameters($category, $base_parameters)

    include("Rings.jl")
    include("Sampling.jl")
    include("Hashing.jl")
    include("ErrorDecoding.jl")
    include("Encoding.jl")

    """
        generate_keys([; δ¹])

    Return a tuple `(; ek, dk)` consisting of an encapsulation key and the corresponding
    decapsulation key. The length of `ek` will be $(lengths.ek) bytes and the length of `dk`
    $(lengths.dk) bytes.

    For a deterministic result, a seed `δ¹` of $(lengths.δ) bytes can be provided.
    """
    function generate_keys(; δ¹::AbstractVector{UInt8} = rand(rng, UInt8, lengths.δ))
        while true
            δ = δ¹
            (s, β, δ¹) = peel(Hashing.G(δ), [lengths.s, (σ₂ * q + σ₁ * t) ÷ 8, lengths.δ])
            (ᾱ, ḡ) = peel(bytes2bits(β), [σ₂ * q, σ₁ * t])

            α = Sampling.field_ordering(ᾱ)
            α !== nothing || continue

            g = Sampling.irreducible(ḡ)
            g !== nothing || continue

            Tp = Sampling.matgen!(view(α, 1:n), g)
            Tp !== nothing || continue
            (T, p) = Tp

            ek = Encoding.ek_encode(T)
            dk = Encoding.dk_encode(δ, p, g, α, s)

            return (; ek, dk)
        end
    end

    """
        encapsulate_secret(ek[; rng])

    Return a tuple `(; K, c)` consisting of a shared secret `K` and a ciphertext `c` from
    which `K` can be recomputed with the decapsulation key `dk` that corresponds to `ek`.
    The parameter `ek` must be a valid encapsulation key of $(lengths.ek) bytes. The length
    of `K` will be $(lengths.K) bytes and the length of `c` $(lengths.c) bytes.

    For a deterministic result, `rng` can be provided. This pseudorandom number generator
    must implement `rand(rng, UInt8, ::Int)`.
    """
    function encapsulate_secret(ek::AbstractVector{UInt8}; rng::AbstractRNG = rng)
        @argcheck length(ek) == lengths.ek

        T = Encoding.ek_decode(ek)
        e = Sampling.fixed_weight(rng)
        c = bits2bytes(first(e, m * t) .⊻ isodd.(T * last(e, k)))

        K = Hashing.H([0x1; [bits2bytes(e); c]])

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

        (δ, p, g, α, s) = Encoding.dk_decode(dk)
        e = ErrorDecoding.decode(bytes2bits(c, m * t), g, α)
        (b, ẽ) = e === nothing ? (0x0, s) : (0x1, e)

        Hashing.H([b; bits2bytes(ẽ); c])
    end

    end # module
end

end # module
