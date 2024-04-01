import ..run_all

import .McEliece.Parameters: category_parameters
import .McEliece.Matrices: rref!, semisystematic_form!

import Random: bitrand

@testset "McEliece.Matrices.rref!" begin
    m = Rational[0 0 1 0 2; 0 2 0 1 2; 1 0 3 3 0]
    rref!(m)

    @test m == Rational[1 0 0 3 -6; 0 1 0 1//2 1; 0 0 1 0 2]
end

@testset "McEliece.Matrices.semisystematic_form!" begin
    m = Bool[
        0 0 0 0 1 1 0 1 1 0
        0 1 1 1 0 1 0 1 1 0
        1 1 1 0 1 1 1 0 0 0
        1 0 1 0 0 0 0 1 1 0
        0 0 0 0 1 1 0 0 1 1
    ]

    p12 = semisystematic_form!(m, 1, 2)
    p48 = semisystematic_form!(m, 4, 8)

    @test m == Bool[
        1 0 0 1 0 1 1 0 0 0
        0 1 0 0 0 0 1 0 0 0
        0 0 1 1 0 1 1 0 1 1
        0 0 0 0 1 1 0 0 1 1
        0 0 0 0 0 0 0 1 0 1
    ]
    @test p12 === nothing
    @test p48 == [2, 3, 5, 8]
end

for category ∈ keys(category_parameters)
    @eval X = McEliece.$category

    if run_all
        S = X.Sampling
        E = X.ErrorDecoding

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
    end

    @testset "McEliece.$category" begin
        (; ek, dk) = X.generate_keys()
        (; K, c) = X.encapsulate_secret(ek)
        K̃ = X.decapsulate_secret(c, dk)

        @test K == K̃
    end
end
