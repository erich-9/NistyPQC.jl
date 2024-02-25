import .SLHDSA.Parameters: level_parameters

@testset "SLHDSA.base_2ᵇ" begin
    import .SLHDSA.General: base_2ᵇ

    f(b, xs) =
        sum(x * big(2)^(b * (i - 1)) for (i, x) ∈ enumerate(reverse(xs)); init = big(0))

    b = rand(2:32)
    l = rand(0:100)

    out_len = 8l ÷ b

    bs = rand(UInt8, l)
    cs = base_2ᵇ(bs, b, out_len)

    @test f(8, bs) >> (8l - out_len * b) == f(b, cs)
end

for level ∈ keys(level_parameters)
    @eval X = SLHDSA.$level

    sk_seed = rand(UInt8, X.n)
    pk_seed = rand(UInt8, X.n)

    sa = X.SecretAddress(sk_seed, pk_seed)
    pa = X.PublicAddress(pk_seed)

    @testset "SLHDSA.$level.WOTS" begin
        msg = rand(UInt8, X.WOTS.π.μ)

        pk₁ = X.WOTS.pk!(sa)
        sig = X.WOTS.sign_message!(sa, msg)
        pk₂ = X.WOTS.pk_from_signature!(pa, sig, msg)

        @test length(pk₁) == X.WOTS.π.ρ
        @test length(sig) == X.WOTS.π.σ
        @test pk₁ == pk₂
    end

    @testset "SLHDSA.$level.XMSS" begin
        msg = rand(UInt8, X.XMSS.π.μ)
        idx = rand(0:(X.XMSS.π.ν - 1))

        pk₁ = X.XMSS.pk!(sa)
        sig = X.XMSS.sign_message!(sa, msg, idx)
        pk₂ = X.XMSS.pk_from_signature!(pa, sig, msg, idx)

        @test length(pk₁) == X.XMSS.π.ρ
        @test length(sig) == X.XMSS.π.σ
        @test pk₁ == pk₂
    end

    @testset "SLHDSA.$level.Hypertree" begin
        msg = rand(UInt8, X.Hypertree.π.μ)
        idx_tree = rand(0:(X.Hypertree.π.ν - 1))
        idx_leaf = rand(0:(X.XMSS.π.ν - 1))

        pk₁ = X.Hypertree.pk(sk_seed, pk_seed)
        sig = X.Hypertree.sign_message(msg, idx_tree, idx_leaf, sk_seed, pk_seed)
        pk₂ = X.Hypertree.pk_from_signature(msg, sig, idx_tree, idx_leaf, pk_seed)

        @test length(pk₁) == X.Hypertree.π.ρ
        @test length(sig) == X.Hypertree.π.σ
        @test pk₁ == pk₂
    end

    @testset "SLHDSA.$level.FORS" begin
        msg = rand(UInt8, X.FORS.π.μ)
        idx_tree = rand(0:(X.Hypertree.π.ν - 1))
        idx_leaf = rand(0:(X.XMSS.π.ν - 1))

        X.Addressing.change_type_to_fors_tree!.([sa, pa], idx_tree, idx_leaf)

        pk₁ = X.FORS.pk!(sa)
        sig = X.FORS.sign_message!(sa, msg)
        pk₂ = X.FORS.pk_from_signature!(pa, sig, msg)

        @test length(pk₁) == X.FORS.π.ρ
        @test length(sig) == X.FORS.π.σ
        @test pk₁ == pk₂
    end

    @testset "SLHDSA.$level (randomized)" begin
        msg = rand(UInt8, 10_000)

        (pk, sk) = X.generate_keys()

        sig = X.sign_message(msg, sk)

        @test X.length(sig) == X.σ
        @test X.verify_signature(msg, sig, pk)
        @test !X.verify_signature(msg, sig[10:end], pk)
        @test !X.verify_signature(msg, map(isqrt, sig), pk)
    end

    @testset "SLHDSA.$level (not randomized)" begin
        z = zeros(UInt8, X.n)
        msg = rand(UInt8, 10_000)

        (pk, sk) = X.generate_keys(; seed = (; sk = z, prf = z, pk = z))

        sig₁ = X.sign_message(msg, sk; randomize = false)
        sig₂ = X.sign_message(msg, sk; randomize = z)

        @test X.verify_signature(msg, sig₁, pk)
        @test X.verify_signature(msg, sig₂, pk)
    end
end
