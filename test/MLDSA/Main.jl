
import .MLDSA.Parameters: level_parameters, n, q, δ_t, ϵ_t
import .MLDSA.General: power2_round
import .MLDSA.NumberTheory: Rq, Tq, ntt, ntt⁻¹

import Base.Iterators: partition
import Random: randperm

@testset "MLDSA.power2_round" begin
    for r ∈ 0:(q - 1)
        (r₁, r₀) = power2_round(r)
        @test r == mod(r₁ * 2^δ_t + r₀, q)
    end
end

@testset "MLDSA.ntt" begin
    f = Rq(mod.(rand(Int, n), q))
    g = ntt⁻¹(ntt(f))
    @test f == g

    f̂ = Tq(mod.(rand(Int, n), q))
    ĝ = ntt(ntt⁻¹(f̂))
    @test f̂ == ĝ
end

for level ∈ keys(level_parameters)
    @eval X = MLDSA.$level

    EC = X.Encoding

    @testset "MLDSA.$level.Encoding" begin
        ρ_A = rand(UInt8, X.lengths.ρ_A)
        K = rand(UInt8, X.lengths.K)
        tr = rand(UInt8, X.lengths.tr)
        c̃ = rand(UInt8, X.lengths.c̃)
        s₁ = [Rq([rand((-X.η):(X.η)) for _ ∈ 1:(X.n)]) for _ ∈ 1:(X.ℓ)]
        s₂ = [Rq([rand((-X.η):(X.η)) for _ ∈ 1:(X.n)]) for _ ∈ 1:(X.k)]
        t₀ = [Rq([rand((-2^(δ_t - 1) + 1):(2^(δ_t - 1))) for _ ∈ 1:(X.n)]) for _ ∈ 1:(X.k)]
        t₁ = [Rq([rand(0:(2^ϵ_t - 1)) for _ ∈ 1:(X.n)]) for _ ∈ 1:(X.k)]
        z = [Rq([rand((-X.γ₁ + 1):(X.γ₁)) for _ ∈ 1:(X.n)]) for _ ∈ 1:(X.ℓ)]
        h = begin
            c = randperm(X.k * n)[1:rand(0:(X.ω))]
            collect(partition([i ∈ c for i ∈ 1:(X.k * n)], n))
        end
        w₁ = [[rand(0:(X.qm_div_2γ₂ - 1)) for _ ∈ 1:(X.n)] for _ ∈ 1:(X.k)]

        @test EC.pk_decode(EC.pk_encode(ρ_A, t₁)) == (ρ_A, t₁)
        @test EC.sk_decode(EC.sk_encode(ρ_A, K, tr, s₁, s₂, t₀)) == (ρ_A, K, tr, s₁, s₂, t₀)
        @test EC.maybe_sig_decode(EC.sig_encode(c̃, z, h)) == (c̃, z, h)
        @test length(EC.w₁_encode(w₁)) == X.n₂ * X.k * Base.top_set_bit(X.qm_div_2γ₂ - 1)
    end

    @testset "MLDSA.$level" begin
        msg = rand(UInt8, 10_000)

        (; sk, pk) = X.generate_keys()

        sig = X.sign_message(msg, sk)

        @test length(sig) == X.lengths.sig
        @test X.verify_signature(msg, sig, pk)
        @test !X.verify_signature(msg, sig[10:end], pk)
        @test !X.verify_signature(msg, map(isqrt, sig), pk)
    end
end
