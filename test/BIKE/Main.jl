import .BIKE.Parameters: category_parameters, ℓ

for category ∈ keys(category_parameters)
    @eval X = BIKE.$category

    R = X.Ring

    @testset "BIKE.$category.Ring.to_bits" begin
        coeffs₁ = rand(Bool, X.r)
        coeffs₂ = R.to_bits(R.Element(coeffs₁))
        @test coeffs₁ == coeffs₂

        f₁ = rand(R.Element)
        f₂ = R.Element(R.to_bits(f₁))
        @test f₁ == f₂
    end

    @testset "BIKE.$category.Ring.to_bytes" begin
        coeffs₁ = rand(UInt8, X.r_bytes)
        coeffs₁[end] >>= 8X.r_bytes - X.r
        coeffs₂ = R.to_bytes(R.Element(coeffs₁))
        @test coeffs₁ == coeffs₂

        f₁ = rand(R.Element)
        f₂ = R.Element(R.to_bytes(f₁))
        @test f₁ == f₂
    end

    @testset "BIKE.$category.Ring" begin
        f₁ = rand(R.Element)
        f₂ = rand(R.Element)
        f₃ = rand(R.Element)

        @test f₁ + zero(R.Element) == f₁
        @test f₁ * one(R.Element) == f₁
        @test f₁ + f₂ == f₂ + f₁
        @test f₁ * f₂ == f₂ * f₁
        @test f₁ + (f₂ + f₃) == (f₁ + f₂) + f₃
        @test f₁ * (f₂ * f₃) == (f₁ * f₂) * f₃
        @test f₁ * (f₂ + f₃) == f₁ * f₂ + f₁ * f₃
        @test f₁ + f₁ == zero(R.Element)

        if !R.isinvertible(f₁)
            f₁ += one(R.Element)
        end

        @test f₁^-1 * f₁ == one(f₁)
    end

    @testset "BIKE.$category.Sampling" begin
        seed = rand(UInt8, ℓ)

        D = X.Sampling.D̂(seed)
        H = X.Sampling.Ĥ(seed)

        @test R.weight.(D) == [X.d, X.d]
        @test sum(R.weight.(H)) == X.t
    end

    @testset "BIKE.$category.Hashing" begin
        K = X.Hashing.K̂(rand(UInt8, ℓ), rand(UInt8, X.r_bytes + ℓ))
        L = X.Hashing.L̂(rand(R.Element), rand(R.Element))

        @test length(K) == ℓ
        @test length(L) == ℓ
    end

    @testset "BIKE.$category" begin
        z = zeros(UInt8, X.ℓ)

        (; ek, dk) = X.generate_keys(; seed = (; h = z, σ = z))
        (; K, c) = X.encapsulate_secret(ek)
        K̃ = X.decapsulate_secret(c, dk)

        @test K == K̃
    end
end
