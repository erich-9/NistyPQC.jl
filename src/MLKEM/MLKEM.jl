module MLKEM

include("Parameters.jl")
include("General.jl")
include("NumberTheory.jl")
include("Sampling.jl")

import .Parameters: category_parameters

for (category, base_parameters) ∈ category_parameters
    @eval module $category

    export generate_keys, encapsulate_secret, decapsulate_secret

    import ...rng
    import ...Utilities: peel
    import ..Parameters: n₂, dₘₐₓ, H, J, G
    import ..Parameters: derived_parameters
    import ..General: byte_encode, byte_decode

    import ArgCheck: @argcheck

    const (category_number, k, (η₁, η₂), (dᵤ, dᵥ)) = $base_parameters
    const (; identifier, λ, lengths) = derived_parameters($category, $base_parameters)

    include("KPKE.jl")

    """
        generate_keys([; z, d])

    Return a tuple `(; ek, dk)` consisting of an encapsulation key and the corresponding
    decapsulation key. The length of `ek` will be $(lengths.ek) bytes and the length of `dk`
    $(lengths.dk) bytes.

    For a deterministic result, a seed `z` of $(lengths.R) bytes for implicit rejection and
    another seed `d` of $n₂ bytes for key generation can be provided.
    """
    function generate_keys(;
        z::AbstractVector{UInt8} = rand(rng, UInt8, lengths.R),
        d::AbstractVector{UInt8} = rand(rng, UInt8, n₂),
    )
        @argcheck length(z) == lengths.R
        @argcheck length(d) == n₂

        (ekₚₖₑ, dkₚₖₑ) = KPKE.generate_keys(d = d)

        ek = ekₚₖₑ
        dk = [dkₚₖₑ; ek; H(ek); z]

        (; ek, dk)
    end

    """
        encapsulate_secret(ek[; m])

    Return a tuple `(; K, c)` consisting of a shared secret `K` and a ciphertext `c` from
    which `K` can be recomputed with the decapsulation key `dk` that corresponds to `ek`.
    The parameter `ek` must be a valid encapsulation key of $(lengths.ek) bytes. The length
    of `K` will be $(lengths.K) bytes and the length of `c` $(lengths.c) bytes.

    For a deterministic result, a plaintext `m` of $n₂ bytes can be provided.
    """
    function encapsulate_secret(
        ek::AbstractVector{UInt8};
        m::AbstractVector{UInt8} = rand(rng, UInt8, n₂),
    )
        @argcheck length(ek) == lengths.ek
        @argcheck first(ek, λ) == byte_encode(dₘₐₓ, byte_decode(dₘₐₓ, first(ek, λ)))
        @argcheck length(m) == n₂

        (K::Vector{UInt8}, r) = G([m; H(ek)])
        c = KPKE.encrypt(ek, m, r)

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

        (dkₚₖₑ, ekₚₖₑ, h, z) = peel(dk, [λ, λ + lengths.K, lengths.H, lengths.R])

        m̃ = KPKE.decrypt(dkₚₖₑ, c)
        (K̃::Vector{UInt8}, r̃) = G([m̃; h])
        K̄ = J([z; c])
        c̃ = KPKE.encrypt(ekₚₖₑ, m̃, r̃)

        c == c̃ ? K̃ : K̄
    end

    end # module
end

end # module
