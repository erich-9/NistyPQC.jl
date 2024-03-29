import .Falcon.Parameters: category_parameters
import .Falcon.Parameters: q, length_salt, τ_sig, sqrt_e_div_2, rcdt

@testset "Falcon.Parameters" begin
    @test q == 12_289
    @test length_salt == 40
    @test τ_sig ≈ 1.1
    @test sqrt_e_div_2 ≈ 1.17
    @test rcdt == [
        3024686241123004913666,
        1564742784480091954050,
        636254429462080897535,
        199560484645026482916,
        47667343854657281903,
        8595902006365044063,
        1163297957344668388,
        117656387352093658,
        8867391802663976,
        496969357462633,
        20680885154299,
        638331848991,
        14602316184,
        247426747,
        3104126,
        28824,
        198,
        1,
        0,
    ]
end

@testset "Falcon.Category1.Parameters (category specific)" begin
    X = Falcon.Category1

    @test isapprox(X.σ, 165.736_617_183, atol = 1e-9, rtol = 0)
    @test isapprox(X.σ_min, 1.277_833_697, atol = 1e-9, rtol = 0)
    @test X.β² == 34_034_726
end

@testset "Falcon.Category5.Parameters (category specific)" begin
    X = Falcon.Category5

    @test isapprox(X.σ, 168.388_571_447, atol = 1e-9, rtol = 0)
    @test isapprox(X.σ_min, 1.298_280_334, atol = 1e-9, rtol = 0)
    @test X.β² == 70_265_242
end

for category ∈ keys(category_parameters)
    @eval X = Falcon.$category

    FR = X.Fourier.Rings
    FT = X.Fourier.Transforms
    EC = X.Encoding

    @testset "Falcon.$category.dft.F0" begin
        R = FR.F0{Float64}

        f = R.(rand(ComplexF64, 2^rand(1:(X.lg_n))))
        g = R.(rand(ComplexF64, X.n))

        @test all(FT.merge_dft(FT.split_dft(f)...) .≈ f)
        @test all(FT.merge(FT.split_dft(FT.merge_dft(FT.split(f)...))...) .≈ f)

        @test all(FT.dft(g) .≈ [evalpoly(FR.ζ(R, i), g) for i ∈ 1:2:(2X.n)])

        @test all(FT.dft⁻¹(FT.dft(g)) .≈ g)
        @test all(FT.dft(FT.dft⁻¹(g)) .≈ g)
    end

    @testset "Falcon.$category.dft.Fq" begin
        R = FR.Fq{Int}

        f = R.(rand(0:(X.q - 1), 2^rand(1:(X.lg_n))))
        g = R.(rand(0:(X.q - 1), X.n))

        @test FT.merge_dft(FT.split_dft(f)...) == f
        @test FT.merge(FT.split_dft(FT.merge_dft(FT.split(f)...))...) == f

        @test FT.dft(g) == [evalpoly(FR.ζ(R, i), g) for i ∈ 1:2:(2X.n)]

        @test FT.dft⁻¹(FT.dft(g)) == g
        @test FT.dft(FT.dft⁻¹(g)) == g
    end

    @testset "Falcon.$category.NTRU.generate" begin
        (f, g, F, G) = X.NTRU.generate()

        @test X.NTRU.polymul(f, G) - X.NTRU.polymul(F, g) == [X.q; zeros(Int, X.n - 1)]
    end

    @testset "Falcon.$category.Encoding" begin
        b = BitVector(repeat([0, 0, 0, 0, 0, 0, 0, 0, 1], X.n))
        s = [EC.headerbyte([0, 0, 1, 1]); zeros(UInt8, X.lengths.sig - 1)]

        @test EC.compress(-100:100, 100) === nothing
        @test EC.decompress(b) !== nothing
        @test EC.decompress([b; true]) === nothing
    end

    @testset "Falcon.$category" begin
        msg = rand(UInt8, 10_000)

        (; sk, pk) = X.generate_keys()

        sig = X.sign_message(msg, sk)

        @test length(sig) == X.lengths.sig
        @test X.verify_signature(msg, sig, pk)
        @test !X.verify_signature(msg, sig[10:end], pk)
        @test !X.verify_signature(msg, map(isqrt, sig), pk)
    end
end
