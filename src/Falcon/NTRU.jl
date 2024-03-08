module NTRU

import ...General: euclidnorm_sqr, max_bitlength, polymul, polymul_x!
import ...Parameters: e_div_2
import ..n, ..q
import ..Fourier: F0, Fq, recompute_big_ζs, merge, split, dft, dft⁻¹, gramdata
import ..Sampling: sample_σ_fg_int

function generate()
    while true
        (f, g) = ([sample_σ_fg_int() for _ ∈ 1:n] for _ ∈ 1:2)
        if invertible(f) && gramnorm_inbound(f, g)
            solution = solve(BigInt.(f), BigInt.(g))
            if solution !== nothing
                (F, G) = solution
                return (f, g, Int.(F), Int.(G))
            end
        end
    end
end

function invertible(f)
    !any(iszero, dft(Fq{Int}.(f)))
end

function gramnorm_inbound(f, g, bound_sqr = e_div_2 * q)
    if euclidnorm_sqr([f, g]) > bound_sqr
        return false
    else
        (f₊, _, g₊, _, fg) = gramdata(f, g)
        return euclidnorm_sqr([f₊ ./ fg, g₊ ./ fg]) * q^2 / n ≤ bound_sqr
    end
end

function solve(f::AbstractVector{T}, g::AbstractVector{T}) where {T}
    if length(f) == 1
        (d, u, v) = gcdx(f[], g[])
        if isone(d)
            return ([-v * q], [u * q])
        end
    else
        solution = solve(fieldnorm.((f, g))...)
        if solution !== nothing
            (F̄, Ḡ) = solution
            return reduce!(twisted_lift(F̄, g), twisted_lift(Ḡ, f), f, g)
        end
    end
end

function fieldnorm(f)
    (f₁, f₂) = split(f)
    polymul(f₁, f₁) - polymul_x!(polymul(f₂, f₂))
end

function twisted_lift(f::AbstractVector{T}, g::AbstractVector{T}) where {T}
    polymul(merge(f, zeros(T, length(f))), [isodd(i) ? x : -x for (i, x) ∈ enumerate(g)])
end

function reduce!(
    F::AbstractVector{T},
    G::AbstractVector{T},
    f::AbstractVector{T},
    g::AbstractVector{T},
) where {T}
    prec = max_bitlength([f, g, F, G])

    setprecision(max(prec, precision(BigFloat))) do
        recompute_big_ζs()

        (f₊, f₋, g₊, g₋, fg) = gramdata(f, g, F0{BigFloat})
        (F₊, G₊) = dft.(F0{BigFloat}.([F, G]))

        k = (x -> convert(T, x)).(dft⁻¹((F₊ .* f₋ + G₊ .* g₋) ./ fg))

        if !iszero(k)
            F -= polymul(k, f)
            G -= polymul(k, g)
        end

        return (F, G)
    end
end

end # module
