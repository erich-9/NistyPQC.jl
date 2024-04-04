import .McEliece.Parameters: category_parameters
import .McEliece.Matrices: rref!, semisystematic_form!

import Random: bitrand

@testset "McEliece.Matrices.rref!" begin
    m = Rational[0 0 1 0 2; 0 2 0 1 2; 1 0 3 3 0]
    rref!(m)

    @test m == Rational[1 0 0 3 -6; 0 1 0 1//2 1; 0 0 1 0 2]
end

@testset "McEliece.Matrices.semisystematic_form!" begin
    m =
        BitVector.(
            eachrow(
                Bool[
                    0 0 0 0 1 1 0 1 1 0
                    0 1 1 1 0 1 0 1 1 0
                    1 1 1 0 1 1 1 0 0 0
                    1 0 1 0 0 0 0 1 1 0
                    0 0 0 0 1 1 0 0 1 1
                ],
            )
        )

    p12 = semisystematic_form!(m, 1, 2)
    p48 = semisystematic_form!(m, 4, 8)

    @test m == eachrow(
        Bool[
            1 0 0 1 0 1 1 0 0 0
            0 1 0 0 0 0 1 0 0 0
            0 0 1 1 0 1 1 0 1 1
            0 0 0 0 1 1 0 0 1 1
            0 0 0 0 0 0 0 1 0 1
        ],
    )
    @test p12 === nothing
    @test p48 == [2, 3, 5, 8]
end

for (category, _) ∈ category_parameters
    @eval X = McEliece.$category

    R = X.Rings
    S = X.Sampling
    E = X.ErrorDecoding

    sample(T) = begin
        if T == R.Fz̄
            R.Fz̄(R.Raw, rand(0:((1 << X.m) - 1)))
        elseif T == R.Fz̄y
            R.Fz̄y([sample(R.Fz̄) for _ ∈ 1:(rand(0:1_000))])
        elseif T == R.Fz̄ȳ
            R.Fz̄ȳ([sample(R.Fz̄) for _ ∈ 1:(X.t + 5)])
        end
    end

    @testset "McEliece.$category.Rings" begin
        for A ∈ [R.Fz̄, R.Fz̄y, R.Fz̄ȳ]
            (f₁, f₂, f₃) = (sample(A) for _ ∈ 1:3)

            @test f₁ + zero(A) == f₁ == -f₁
            @test f₁ * one(A) == f₁
            @test f₁ + f₂ == f₂ + f₁
            @test f₁ * f₂ == f₂ * f₁
            @test f₁ + (f₂ + f₃) == (f₁ + f₂) + f₃
            @test f₁ * (f₂ * f₃) == (f₁ * f₂) * f₃
            @test f₁ * (f₂ + f₃) == f₁ * f₂ + f₁ * f₃
            @test f₁ + f₁ == zero(A)
            @test (f₁ + f₂)^2 == f₁^2 + f₂^2
            @test iszero(f₁ - f₁)
            @test isone(copy(one(A)))

            if A ∈ [R.Fz̄, R.Fz̄ȳ] && !iszero(f₁)
                @test f₁^-1 * f₁ == one(f₁)
                @test f₂ / f₁ * f₁ == f₂
            end

            if A ∈ [R.Fz̄y, R.Fz̄ȳ]
                @test A(R.coeffs(R.Fz̄, f₁)) == f₁
            end

            if A == R.Fz̄y
                (q, r) = divrem(f₁, f₂)
                @test f₁ == q * f₂ + r
                @test (q, r) == (f₁ ÷ f₂, f₁ % f₂)

                @test E.approximant(f₁, f₁) == (zero(A), one(A), one(A))
            end
        end
    end

    @testset "McEliece.$category.ErrorDecoding" begin
        bits₁ = bitrand(X.σ₁ * X.t)
        bits₂ = bitrand(X.σ₂ * X.q)

        g = S.irreducible(bits₁)
        α = S.field_ordering(bits₂)
        e = S.fixed_weight(NistyPQC.rng)

        @test count(isone, e) == X.t

        if g !== nothing && α !== nothing
            Tp = S.matgen!(view(α, 1:(X.n)), g)
            if Tp !== nothing
                (T, p) = Tp

                @test length(p) == X.μ
                @test size(T) == (X.m * X.t, X.k)

                c = first(e, X.m * X.t) .⊻ isodd.(T * last(e, X.k))
                ẽ = E.decode(c, g, α)

                @test ẽ == e
            end
        end
    end

    @testset "McEliece.$category" begin
        (; ek, dk) = X.generate_keys()
        (; K, c) = X.encapsulate_secret(ek)
        K̃ = X.decapsulate_secret(c, dk)

        @test K == K̃
    end
end
