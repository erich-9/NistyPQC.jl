import .BIKE
import .BIKE.Parameters: level_parameters, λ

repetitions = 1

for level ∈ keys(level_parameters)
    @eval X = BIKE.$level

    @testset "BIKE.$level.bits2ring" begin
        for _ ∈ 1:repetitions
            coeffs₁ = BitVector(rand(Bool, X.r))
            coeffs₂ = X.Ring.ring2bits(X.Ring.bits2ring(coeffs₁))
            @test coeffs₁ == coeffs₂

            f₁ = rand(X.Ring.Element)
            f₂ = X.Ring.bits2ring(X.Ring.ring2bits(f₁))
            @test f₁ == f₂
        end
    end

    @testset "BIKE.$level.bytes2ring" begin
        for _ ∈ 1:repetitions
            coeffs₁ = Vector{UInt8}(rand(Bool, X.r_bytes))
            coeffs₂ = X.Ring.ring2bytes(X.Ring.bytes2ring(coeffs₁))
            @test coeffs₁ == coeffs₂

            f₁ = rand(X.Ring.Element)
            f₂ = X.Ring.bytes2ring(X.Ring.ring2bytes(f₁))
            @test f₁ == f₂
        end
    end

    # @testset "Ring" begin
    #     import .BIKE.Ring: Element, isinvertible

    #     for _ ∈ 1:repetitions
    #         f₁ = rand(Element)
    #         f₂ = rand(Element)
    #         f₃ = rand(Element)

    #         @test f₁ + zero(Element) == f₁
    #         @test f₁ * one(Element) == f₁
    #         @test f₁ + f₂ == f₂ + f₁
    #         @test f₁ * f₂ == f₂ * f₁
    #         @test f₁ + (f₂ + f₃) == (f₁ + f₂) + f₃
    #         @test f₁ * (f₂ * f₃) == (f₁ * f₂) * f₃
    #         @test f₁ * (f₂ + f₃) == f₁ * f₂ + f₁ * f₃
    #         @test f₁ + f₁ == zero(Element)
    #         @test !isinvertible(f₁) || f₁^-1 * f₁ == one(Element)
    #     end
    # end

    # @testset "Sampling" begin
    #     import .BIKE.Parameters: w, t
    #     import .BIKE.Ring: Element, ring2bits
    #     import .BIKE.Sampling: D̂, Ĥ, K̂, L̂

    #     for _ ∈ 1:repetitions
    #         seed = rand(UInt8, 32)

    #         D = D̂(seed)
    #         H = Ĥ(seed)
    #         K = K̂(rand(UInt8, 32), rand(UInt8, 32))
    #         L = L̂(rand(Element), rand(Element))

    #         @test sum(ring2bits(D)) == w ÷ 2
    #         @test sum(map(sum ∘ ring2bits, H)) == t
    #         @test length(K) == λ
    #         @test length(L) == λ
    #     end
    # end

    # @testset "BIKE" begin
    #     import .BIKE: generate_keys, encapsulate_secret, decapsulate_secret

    #     for _ ∈ 1:repetitions
    #         (; ek, dk) = generate_keys()
    #         (; K, c) = encapsulate_secret(ek)
    #         K̃ = decapsulate_secret(c, dk)

    #         @test K == K̃
    #     end
    # end
end
