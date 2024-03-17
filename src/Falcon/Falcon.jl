module Falcon

include("Parameters.jl")
include("General.jl")

import .Parameters: category_parameters

for (category, base_parameters) ∈ category_parameters
    @eval module $category

    export generate_keys, sign_message, verify_signature

    import ...rng
    import ..Parameters: q, σ_max, derived_parameters
    import ..General: euclidnorm_sqr

    import ArgCheck: @argcheck

    const (category_number, lg_λ, lg_n, _) = $base_parameters
    const (; identifier, n, σ_fg, σ, σ_min, β², bitlengths, lengths) =
        derived_parameters($category, $base_parameters)

    include("Sampling.jl")
    include("Fourier/Fourier.jl")
    include("NTRU.jl")
    include("Hashing.jl")

    import .Fourier: F0, Fq, dft, dft⁻¹

    struct PublicKey
        h::Vector{Fq{Int}}
    end

    struct SecretKey
        f::Vector{Int}
        g::Vector{Int}
        F::Vector{Int}
        G::Vector{Int}

        f₊::Vector{F0{Float64}}
        g₊::Vector{F0{Float64}}
        F₊::Vector{F0{Float64}}
        G₊::Vector{F0{Float64}}

        root::Fourier.Tree.InnerNode{Float64}

        function SecretKey(f, g, F, G)
            new(f, g, F, G, Fourier.Tree.generate(f, g, F, G)...)
        end

        function SecretKey(f, g, F)
            (f̂, ĝ, F̂) = (dft(Fq{Int}.(x)) for x ∈ (f, g, F))
            SecretKey(f, g, F, (x -> convert(Int, x)).(dft⁻¹(ĝ .* F̂ ./ f̂)))
        end
    end

    struct Signature
        salt::Vector{UInt8}
        s₂::Vector{Int}
    end

    include("Encoding.jl")

    function generate_keys()
        (f, g, F, G) = NTRU.generate()
        (f̂, ĝ) = (dft(Fq{Int}.(x)) for x ∈ (f, g))

        pk = Encoding.encode(PublicKey(dft⁻¹(ĝ ./ f̂)))
        sk = Encoding.encode(SecretKey(f, g, F, G))

        (; sk, pk)
    end

    function sign_message(
        msg::AbstractVector{UInt8},
        sk::AbstractVector{UInt8};
        salt::AbstractVector{UInt8} = rand(rng, UInt8, lengths.salt),
    )
        @argcheck length(salt) == lengths.salt

        (f₊, g₊, F₊, G₊, root) = let sk = Encoding.decode(SecretKey, sk)
            (getproperty(sk, p) for p ∈ [:f₊, :g₊, :F₊, :G₊, :root])
        end

        c = Hashing.hash_to_point([salt; msg])

        u = dft(F0{Float64}.(c ./ q))
        (t₁, t₂) = (-u .* F₊, u .* f₊)

        while true
            (z₁, z₂) = Fourier.Sampling.sample_dft_pair(t₁, t₂, root)
            (w₁, w₂) = (t₁ .- z₁, t₂ .- z₂)
            (ŝ₁, ŝ₂) = [w₁ .* g₊ .+ w₂ .* G₊, -(w₁ .* f₊ .+ w₂ .* F₊)]

            if euclidnorm_sqr([ŝ₁, ŝ₂]) / n ≤ β²
                sig = Encoding.maybe_encode(
                    Signature(salt, (x -> convert(Int, x)).(dft⁻¹(ŝ₂))),
                )
                sig === nothing && continue
                return sig
            end
        end
    end

    function verify_signature(
        msg::AbstractVector{UInt8},
        sig::AbstractVector{UInt8},
        pk::AbstractVector{UInt8},
    )
        h = Encoding.decode(PublicKey, pk).h

        (salt, s₂) = let sig = Encoding.maybe_decode(Signature, sig)
            sig === nothing && return false
            (getproperty(sig, p) for p ∈ [:salt, :s₂])
        end

        c = Hashing.hash_to_point([salt; msg])
        s₁ = (x -> convert(Int, x)).(Fq{Int}.(c) .- dft⁻¹(dft(Fq{Int}.(s₂)) .* dft(h)))

        euclidnorm_sqr([s₁, s₂]) ≤ β²
    end

    end # module
end

end # module
