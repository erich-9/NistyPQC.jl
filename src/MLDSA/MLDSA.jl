module MLDSA

include("Parameters.jl")
include("General.jl")
include("NumberTheory.jl")

import .Parameters: category_parameters

for (category, base_parameters) ∈ category_parameters
    @eval module $category

    export generate_keys, sign_message, verify_signature

    import ...rng
    import ...Utilities: peel
    import ..Parameters: n, n₂, q, δ_t, H, H₁₂₈
    import ..Parameters: derived_parameters
    import ..General: modq⁺⁻, power2_round
    import ..NumberTheory: Rq, ntt, ntt⁻¹, map_coeffwise

    import ArgCheck: @argcheck

    const (category_number, λ, (k, ℓ), τ, η, ω, qm_div_2γ₂, _) = $base_parameters
    const (; γ₁, γ₂, β, lengths) = derived_parameters($category, $base_parameters)

    include("Hints.jl")
    include("Encoding.jl")
    include("Sampling.jl")

    function generate_keys(; ξ::AbstractVector{UInt8} = rand(rng, UInt8, lengths.ξ))
        @argcheck length(ξ) == lengths.ξ

        (ρ_A, ρ_S, K) = peel(H(ξ), [lengths.ρ_A, lengths.ρ_S, lengths.K])

        Â = Sampling.expand_A(ρ_A)
        (s₁, s₂) = Sampling.expand_S(ρ_S)
        t = ntt⁻¹.(Â * ntt.(s₁)) + s₂
        (t₁, t₀) = map_coeffwise(power2_round, t, 2)

        pk = Encoding.pk_encode(ρ_A, t₁)
        tr = H(pk, lengths.tr)
        sk = Encoding.sk_encode(ρ_A, K, tr, s₁, s₂, t₀)

        (; sk, pk)
    end

    function sign_message(
        msg::AbstractVector{UInt8},
        sk::AbstractVector{UInt8};
        randomize::Union{Bool, AbstractVector{UInt8}} = true,
    )
        (ρ_A, K, tr, s₁, s₂, t₀) = Encoding.sk_decode(sk)

        rnd = if randomize isa AbstractVector{UInt8}
            @argcheck length(randomize) == lengths.rnd
            randomize
        elseif randomize === false
            zeros(UInt8, lengths.rnd)
        else
            rand(rng, UInt8, lengths.rnd)
        end

        (ŝ₁, ŝ₂, t̂₀) = (ntt.(f) for f ∈ (s₁, s₂, t₀))
        Â = Sampling.expand_A(ρ_A)

        μ = H(vcat(tr, msg), lengths.μ)
        ρ_mask = H(vcat(K, rnd, μ), lengths.ρ_mask)

        for κ ∈ Iterators.countfrom(0, ℓ)
            y = Sampling.expand_mask(ρ_mask, κ)
            w = ntt⁻¹.(Â * ntt.(y))
            w₁ = map_coeffwise(Hints.high_bits, w)

            c̃ = H(vcat(μ, Encoding.w₁_encode(w₁)), lengths.c̃)

            ĉ = ntt(Sampling.sample_in_ball(first(c̃, lengths.c̃₁)))
            (cs₁, cs₂) = (ntt⁻¹.(ĉ * f̂) for f̂ ∈ (ŝ₁, ŝ₂))

            z = map_coeffwise(modq⁺⁻, y + cs₁)
            any(abs(x) ≥ γ₁ - β for v ∈ z for x ∈ v) && continue

            r₀ = map_coeffwise(Hints.low_bits, w - cs₂)
            any(abs(x) ≥ γ₂ - β for v ∈ r₀ for x ∈ v) && continue

            ct₀ = map_coeffwise(modq⁺⁻, ntt⁻¹.(ĉ * t̂₀))
            any(abs(x) ≥ γ₂ for v ∈ ct₀ for x ∈ v) && continue

            h = [Hints.make_hint.(a, b) for (a, b) ∈ zip(-ct₀, w - cs₂ + ct₀)]
            count(x for v ∈ h for x ∈ v) > ω && continue

            return Encoding.sig_encode(c̃, z, h)
        end
    end

    function verify_signature(
        msg::AbstractVector{UInt8},
        sig::AbstractVector{UInt8},
        pk::AbstractVector{UInt8},
    )
        (ρ_A, t₁) = Encoding.pk_decode(pk)

        (c̃, z, h) = let sig = Encoding.maybe_sig_decode(sig)
            sig === nothing && return false
            sig
        end

        Â = Sampling.expand_A(ρ_A)

        tr = H(pk, lengths.tr)
        μ = H(vcat(tr, msg), lengths.μ)

        c = Sampling.sample_in_ball(first(c̃, lengths.c̃₁))

        w̄_approx = ntt⁻¹.(Â * ntt.(z) - ntt(c) * ntt.(2^δ_t * t₁))
        w̄₁ = [Rq(Hints.use_hint.(a, b)) for (a, b) ∈ zip(h, w̄_approx)]

        c̄ = H(vcat(μ, Encoding.w₁_encode(w̄₁)), lengths.c̃)

        c̃ == c̄ &&
            all(abs(x) < γ₁ - β for v ∈ z for x ∈ v) &&
            count(x for v ∈ h for x ∈ v) ≤ ω
    end

    end # module
end

end # module
