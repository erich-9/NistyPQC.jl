module Polynomials

import ...t
import ..Raw, ..Ring
import ..BaseField: Fz̄, coeffs

mutable struct Fz̄y <: Ring
    d::Vector{Fz̄}
    Fz̄y(::Type{Raw}, d) = new(d)
end

const y = Fz̄y(Raw, [zero(Fz̄); one(Fz̄)])
Base.zero(::Type{Fz̄y}) = Fz̄y(Raw, [])
Base.one(::Type{Fz̄y}) = Fz̄y(Raw, [one(Fz̄)])

Base.zero(::Fz̄y) = zero(Fz̄y)
Base.one(::Fz̄y) = one(Fz̄y)

Base.iszero(a::Fz̄y) = length(a.d) == 0
Base.isone(a::Fz̄y) = length(a.d) == 1 && isone(a.d[1])

Base.promote_rule(::Type{Fz̄y}, ::Union{Type{<:Integer}, Type{Fz̄}}) = Fz̄y
Base.convert(::Type{Fz̄y}, a::Union{<:Integer, Fz̄}) =
    iszero(a) ? zero(Fz̄y) : Fz̄y([convert(Fz̄, a)])

Base.getindex(a::Fz̄y, i::Integer) = i + 1 > length(a.d) ? zero(Fz̄) : a.d[i + 1]
coeffs(::Type{Fz̄}, a::Fz̄y) = a.d
degree(a::Fz̄y) = length(a.d) - 1

function Fz̄y(x::AbstractVector{Fz̄})
    i₀ = findlast(!iszero, x)
    if i₀ === nothing
        zero(Fz̄y)
    else
        Fz̄y(Raw, view(x, 1:i₀))
    end
end

function Fz̄y!(x::Vector{Fz̄}; bound = length(x))
    Fz̄y(Raw, strip_zeros!(x, bound))
end

Base.copy(a::Fz̄y) = Fz̄y(Raw, copy(a.d))
Base.:(==)(a::Fz̄y, b::Fz̄y) = a.d == b.d
Base.:-(a::Fz̄y, b::Fz̄y) = a + b
Base.:-(a::Fz̄y) = a
Base.:^(a::Fz̄y, p::Integer) = Base.power_by_squaring(a, p)
(a::Fz̄y)(x::Fz̄) = evalpoly(x, a.d)

function Base.:+(a::Fz̄y, b::Fz̄y)
    (len_a, len_b) = (length(a.d), length(b.d))
    @inbounds if len_a == len_b
        len = len_a
        while len > 0
            s = a.d[len] + b.d[len]
            if !iszero(s)
                x = Vector{Fz̄}(undef, len)
                x[len] = s
                for i ∈ 1:(len - 1)
                    x[i] = a.d[i] + b.d[i]
                end
                return Fz̄y(Raw, x)
            end
            len -= 1
        end
        if len == 0
            return Fz̄y(Raw, [])
        end
    else
        if len_a < len_b
            (a, b) = (b, a)
            (len_a, len_b) = (len_b, len_a)
        end
        x = Vector{Fz̄}(undef, len_a)
        for i ∈ 1:len_b
            x[i] = a.d[i] + b.d[i]
        end
        for i ∈ (len_b + 1):len_a
            x[i] = a.d[i]
        end
        return Fz̄y(Raw, x)
    end
end

function Base.:*(a::Fz̄y, b::Fz̄y)
    if iszero(a) || iszero(b)
        zero(Fz̄y)
    else
        Fz̄y(Raw, polymul!(zeros(Fz̄, length(a.d) + length(b.d) - 1), a.d, b.d))
    end
end

function Base.:÷(a::Fz̄y, b::Fz̄y)
    qr = _divrem(a.d, b.d)
    qr === nothing ? zero(Fz̄y) : Fz̄y!(first(qr))
end

function Base.:%(a::Fz̄y, b::Fz̄y)
    qr = _divrem(a.d, b.d)
    qr === nothing ? a : Fz̄y!(last(qr))
end

function Base.divrem(a::Fz̄y, b::Fz̄y)
    qr = _divrem(a.d, b.d)
    qr === nothing ? (zero(Fz̄y), a) : Fz̄y!.(qr)
end

function polymul!(x, a, b)
    @inbounds for i ∈ eachindex(a)
        for j ∈ eachindex(b)
            x[i + j - 1] += a[i] * b[j]
        end
    end
    x
end

function _divrem(a, b)
    (len_a, len_b) = (length(a), length(b))
    deg = len_a - len_b + 1
    deg ≤ 0 && return nothing
    (q, r) = (zeros(Fz̄, deg), copy(a))
    κ = inv(b[len_b])
    @inbounds for i ∈ len_a:-1:len_b
        λ = κ * r[i]
        q[i - len_b + 1] = λ
        for j ∈ eachindex(b)
            r[i - len_b + j] -= λ * b[j]
        end
    end
    (q, r)
end

function strip_zeros!(x, bound)
    while bound > 0 && iszero(@inbounds x[bound])
        bound -= 1
    end
    if length(x) > bound
        resize!(x, bound)
    end
    x
end

end # module
