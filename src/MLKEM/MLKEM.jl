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
    import ..Parameters: n₂, dₘₐₓ, length_H, length_J, length_K, length_R, H, J, G
    import ..Parameters: derived_parameters
    import ..General: byte_encode, byte_decode

    import ArgCheck: @argcheck
    import StaticArrays: StaticVector

    const (level_number, k, (η₁, η₂), (dᵤ, dᵥ)) = $base_parameters
    const (; identifier, λ) = derived_parameters($level, $base_parameters)

    const length_ek = λ + length_K
    const length_dk = λ + length_ek + length_H + length_R
    const length_c = n₂ * (dᵤ * k + dᵥ)

    include("KPKE.jl")

    function generate_keys(;
        z::AbstractVector{UInt8} = rand(rng, UInt8, length_R),
        d::AbstractVector{UInt8} = rand(rng, UInt8, n₂),
    )
        @argcheck length(z) == length_R
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
        @argcheck length(ek) == length_ek
        @argcheck ek[1:λ] == byte_encode(dₘₐₓ, byte_decode(dₘₐₓ, ek[1:λ]))
        @argcheck length(m) == n₂

        (K::Vector{UInt8}, r) = G([m; H(ek)])
        c = KPKE.encrypt(ek, m, r)

        (; K, c)
    end

    function decapsulate_secret(c::AbstractVector{UInt8}, dk::AbstractVector{UInt8})
        @argcheck length(c) == length_c
        @argcheck length(dk) == length_dk

        dkₚₖₑ = dk[1:λ]
        ekₚₖₑ = dk[(λ + 1):(2λ + length_K)]
        h = dk[(end - length_R - length_H + 1):(end - length_R)]
        z = dk[(end - length_R + 1):end]

        m̃ = KPKE.decrypt(dkₚₖₑ, c)
        (K̃::Vector{UInt8}, r̃) = G([m̃; h])
        K̄ = J([z; c])
        c̃ = KPKE.encrypt(ekₚₖₑ, m̃, r̃)

        c == c̃ ? K̃ : K̄
    end

    end # module
end

end # module
