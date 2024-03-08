module MLKEM

include("Parameters.jl")
include("General.jl")
include("NumberTheory.jl")
include("Sampling.jl")

import .Parameters: level_parameters

for (level, base_parameters) ∈ level_parameters
    @eval module $level

    export generate_keys, encapsulate_secret, decapsulate_secret

    import ...rng
    import ...Utilities: peel
    import ..Parameters: n₂, dₘₐₓ, H, J, G
    import ..Parameters: derived_parameters
    import ..General: byte_encode, byte_decode

    import ArgCheck: @argcheck

    const (level_number, k, (η₁, η₂), (dᵤ, dᵥ)) = $base_parameters
    const (; identifier, λ, lengths) = derived_parameters($level, $base_parameters)

    include("KPKE.jl")

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
