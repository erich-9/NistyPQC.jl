import .MLKEM
import .MLKEM.Parameters: level_parameters, n, n₂, q, dₘₐₓ

@testset "bits2bytes" begin
    import .MLKEM.General: bytes2bits, bits2bytes

    l = rand(0:10_000)

    b = BitVector(rand(Bool, l << 3))
    c = bytes2bits(bits2bytes(b))
    @test b == c

    B = Vector{UInt8}(rand(UInt8, l))
    C = bits2bytes(bytes2bits(B))
    @test B == C
end

@testset "compress" begin
    import .MLKEM.General: compress, decompress

    mod⁺⁻(x, m) = mod(x, (-(m + 1) ÷ 2 + 1):(m ÷ 2))

    for x ∈ 1:q
        for d ∈ 0:(dₘₐₓ - 1)
            y = compress(d, decompress(d, x))
            @test x == y
        end
    end

    for x ∈ 1:q
        for d ∈ 0:(dₘₐₓ - 1)
            y = decompress(d, compress(d, x))
            @test y - x == mod⁺⁻(y - x, q)
            @test abs(y - x) ≤ div(q, (1 << (d + 1)), RoundNearestTiesUp)
        end
    end
end

@testset "byte_encode" begin
    import .MLKEM.General: byte_encode, byte_decode

    for d ∈ 1:dₘₐₓ
        m = d < dₘₐₓ ? 1 << d : q
        F = mod.(rand(Int, n), m)
        G = byte_decode(d, byte_encode(d, F))
        @test F == G
    end

    for d ∈ 1:(dₘₐₓ - 1)
        B = rand(UInt8, d * n >> 3)
        C = byte_encode(d, byte_decode(d, B))
        @test B == C
    end
end

@testset "ntt" begin
    import .MLKEM.NumberTheory: R_q, T_q, ntt, ntt⁻¹

    f = R_q(mod.(rand(Int, n), q))
    g = ntt⁻¹(ntt(f))
    @test f == g

    f̂ = T_q(mod.(rand(Int, n), q))
    ĝ = ntt(ntt⁻¹(f̂))
    @test f̂ == ĝ
end

for level ∈ keys(level_parameters)
    @eval X = MLKEM.$level

    @testset "$level.KPKE" begin
        m = rand(UInt8, n₂)
        r = rand(UInt8, 32)

        (; ek, dk) = X.KPKE.generate_keys()
        c = X.KPKE.encrypt(ek, m, r)
        m̃ = X.KPKE.decrypt(dk, c)

        @test m == m̃
    end

    @testset "$level.MLKEM" begin
        (; ek, dk) = X.generate_keys()
        (; K, c) = X.encapsulate_secret(ek)
        K̃ = X.decapsulate_secret(c, dk)

        @test K == K̃
    end
end
