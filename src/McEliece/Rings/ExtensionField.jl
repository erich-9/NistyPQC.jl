module ExtensionField

import ...t, ...F
import ..Raw, ..Ring
import ..BaseField: Fz̄, z̄, coeffs
import ..Polynomials: Fz̄y, Fz̄y!, y, polymul!

const F̃ = sum(sum(z̄^i for i ∈ c) * y^j for (j, c) ∈ F)

struct Fz̄ȳ <: Ring
    d::Fz̄y
    Fz̄ȳ(::Type{Raw}, d) = new(d)
end

const ȳ = Fz̄ȳ(Raw, y)
Base.zero(::Type{Fz̄ȳ}) = Fz̄ȳ(Raw, zero(Fz̄y))
Base.one(::Type{Fz̄ȳ}) = Fz̄ȳ(Raw, one(Fz̄y))

Base.zero(::Fz̄ȳ) = zero(Fz̄ȳ)
Base.one(::Fz̄ȳ) = one(Fz̄ȳ)

Base.iszero(a::Fz̄ȳ) = iszero(a.d)
Base.isone(a::Fz̄ȳ) = isone(a.d)

Base.promote_rule(::Type{Fz̄ȳ}, ::Union{Type{<:Integer}, Type{Fz̄}}) = Fz̄ȳ
Base.convert(::Type{Fz̄ȳ}, a::Union{<:Integer, Fz̄}) = Fz̄ȳ(convert(Fz̄y, a))

coeffs(::Type{Fz̄}, a::Fz̄ȳ) = [a.d[i] for i ∈ 0:(t - 1)]

Fz̄ȳ(a::Fz̄y) = Fz̄ȳ!(copy(a))
Fz̄ȳ(coeffs::AbstractVector{Fz̄}) = Fz̄ȳ!(Fz̄y(coeffs))
Fz̄ȳ!(a::Fz̄y) = Fz̄ȳ(Raw, length(a.d) > t ? _mod_padded!(a.d) : a)

Base.copy(a::Fz̄ȳ) = Fz̄ȳ(Raw, copy(a.d))
Base.:(==)(a::Fz̄ȳ, b::Fz̄ȳ) = a.d == b.d
Base.:+(a::Fz̄ȳ, b::Fz̄ȳ) = Fz̄ȳ(Raw, a.d + b.d)
Base.:-(a::Fz̄ȳ, b::Fz̄ȳ) = a + b
Base.:-(a::Fz̄ȳ) = a
Base.:^(a::Fz̄ȳ, p::Integer) = Base.power_by_squaring(a, p)
Base.:/(a::Fz̄ȳ, b::Fz̄ȳ) = a * inv(b)

function Base.:*(a::Fz̄ȳ, b::Fz̄ȳ)
    Fz̄ȳ(Raw, _mod!(polymul!(zeros(Fz̄, 2t - 1), a.d.d, b.d.d)))
end

function Base.inv(a::Fz̄ȳ)
    (r₀, r) = (a.d, F̃)
    (s₀, s) = (one(Fz̄y), zero(Fz̄y))
    while !iszero(r)
        q = r₀ ÷ r
        (r₀, r) = (r, r₀ - q * r)
        (s₀, s) = (s, s₀ - q * s)
    end
    s₀.d *= inv(r₀[0])
    Fz̄ȳ(Raw, s₀)
end

function _mod_padded!(x)
    if length(x) < 2t - 1
        append!(x, zeros(Fz̄, 2t - 1 - length(x)))
    end
    _mod!(x)
end

@generated function _mod!(x)
    reduce_coeff(jc) =
        let (j, _) = jc
            if isone(F̃[j])
                :(x[i + $j] += x[i + $t])
            else
                :(x[i + $j] += $(F̃[j]) * x[i + $t])
            end
        end
    quote
        @inbounds for i ∈ ($(t - 1)):-1:1
            $(Expr(:block, reduce_coeff.(F[2:end])...))
        end
        Fz̄y!(x; bound = min(length(x), t))
    end
end

end # module
