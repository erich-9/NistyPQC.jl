import .MLKEM.Parameters: category_parameters, n, n₂, q, dₘₐₓ
import .MLKEM.General: bytes2bits, bits2bytes
import .MLKEM.General: compress, decompress
import .MLKEM.General: byte_encode, byte_decode
import .MLKEM.NumberTheory: Rq, Tq, ntt, ntt⁻¹

@testset "MLKEM.bits2bytes" begin
    l = rand(0:10_000)

    b = BitVector(rand(Bool, l << 3))
    c = bytes2bits(bits2bytes(b))
    @test b == c

    B = Vector{UInt8}(rand(UInt8, l))
    C = bits2bytes(bytes2bits(B))
    @test B == C
end

@testset "MLKEM.compress" begin
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

@testset "MLKEM.byte_encode" begin
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

@testset "MLKEM.ntt" begin
    f = Rq(mod.(rand(Int, n), q))
    g = ntt⁻¹(ntt(f))
    @test f == g

    f̂ = Tq(mod.(rand(Int, n), q))
    ĝ = ntt(ntt⁻¹(f̂))
    @test f̂ == ĝ
end

for category ∈ keys(category_parameters)
    @eval X = MLKEM.$category

    @testset "MLKEM.$category.KPKE" begin
        m = rand(UInt8, n₂)
        r = rand(UInt8, 32)

        (; ek, dk) = X.KPKE.generate_keys()
        c = X.KPKE.encrypt(ek, m, r)
        m̃ = X.KPKE.decrypt(dk, c)

        @test m == m̃
    end

    @testset "MLKEM.$category" begin
        (; ek, dk) = X.generate_keys()
        (; K, c) = X.encapsulate_secret(ek)
        K̃ = X.decapsulate_secret(c, dk)

        @test K == K̃
    end
end
