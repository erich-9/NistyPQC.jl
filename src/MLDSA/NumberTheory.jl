module NumberTheory

import ..Parameters: lg_n, n, q, ζ, n⁻¹

bitrev(i) = parse(Int, reverse(bitstring(i))[1:lg_n], base = 2)

const ζ_bitrev = [powermod(ζ, bitrev(i), q) for i ∈ 1:(n - 1)]
const ζ_2bitrevp = [powermod(ζ, 2bitrev(i) + 1, q) for i ∈ 0:(n - 1)]

for F ∈ [:Rq, :Tq]
    @eval begin
        struct $F
            data::Vector{Int}
        end

        Base.zero(::Type{$F}) = $F(zeros(Int, n))
        Base.zero(::$F) = zero($F)

        function map_coeffwise(func, xs::AbstractVector{$F}, dim_rg = 1)
            res = [[$F(Vector{Int}(undef, n)) for _ ∈ 1:length(xs)] for _ ∈ 1:dim_rg]

            for (i, x) ∈ enumerate(xs)
                for (j, a) ∈ enumerate(x)
                    for (d, b) ∈ enumerate(func(a))
                        res[d][i].data[j] = b
                    end
                end
            end

            dim_rg == 1 ? res[] : res
        end

        Base.:(*)(x::Integer, f̂::$F) = $F(mod.(x * f̂.data, q))
    end

    for (signatures, map_back) ∈ [
        ([([:getindex, :iterate], 1, [[], [:(x::Int)]])], false),
        ([([:length], 1, [[]]), ([:(==)], 2, [[]])], false),
        ([([:(-)], 1, [[]]), ([:(+), :(-)], 2, [[]])], true),
    ]
        for (ops, arity, argss_lhs) ∈ signatures
            for op ∈ ops
                for args_lhs ∈ argss_lhs
                    args_F_lhs = (:($(Symbol(:x, i))::$F) for i ∈ 1:arity)
                    args_F_rhs = (:($(Symbol(:x, i)).data) for i ∈ 1:arity)

                    args_rhs = [x.args[1] for x ∈ args_lhs]

                    lhs = :(Base.$op($(args_F_lhs...), $(args_lhs...)))
                    rhs = :($op($(args_F_rhs...), $(args_rhs...)))

                    if map_back
                        rhs = :($F(mod.($rhs, q)))
                    end

                    @eval $lhs = $rhs
                end
            end
        end
    end
end

Base.:(*)(f̂::Tq, ĝ::Tq) = Tq(mod.(f̂ .* ĝ, q))
Base.:(*)(f̂::Tq, Â::AbstractArray{Tq}) = [f̂ * ĝ for ĝ ∈ Â]

function ntt(f::Rq)
    f̂ = copy(f.data)

    i = 1
    ϕ = n
    @inbounds while ϕ > 1
        ϕ >>= 1
        for s ∈ 0:(2ϕ):(n - 1)
            z = ζ_bitrev[i]
            i += 1
            for j ∈ (s + 1):(s + ϕ)
                t = z * f̂[j + ϕ]
                f̂[j + ϕ] = mod(f̂[j] - t, q)
                f̂[j] = mod(f̂[j] + t, q)
            end
        end
    end

    Tq(f̂)
end

function ntt⁻¹(f̂::Tq)
    f = copy(f̂.data)

    i = n - 1
    ϕ = 1
    @inbounds while ϕ < n
        for s ∈ 0:(2ϕ):(n - 1)
            z = ζ_bitrev[i]
            i -= 1
            for j ∈ (s + 1):(s + ϕ)
                t = f[j]
                f[j] = mod(t + f[j + ϕ], q)
                f[j + ϕ] = mod(z * (f[j + ϕ] - t), q)
            end
        end
        ϕ <<= 1
    end

    Rq(mod.(f * n⁻¹, q))
end

end # module
