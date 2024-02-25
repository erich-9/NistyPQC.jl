module Transforms

import ..Rings: F0, one_half, ζ

function dft(f::AbstractVector)
    if length(f) == 1
        f
    else
        merge_dft(dft.(split(f))...)
    end
end

function dft⁻¹(f::AbstractVector)
    if length(f) == 1
        f
    else
        merge(dft⁻¹.(split_dft(f))...)
    end
end

function merge(f₁::AbstractVector, f₂::AbstractVector)
    collect(Iterators.flatten(zip(f₁, f₂)))
end

function split(f::AbstractVector)
    (f[begin:2:end], f[(begin + 1):2:end])
end

function merge_dft(f₁::AbstractVector{T}, f₂::AbstractVector{T}) where {T}
    l = min(length(f₁), length(f₂))

    f = Vector{T}(undef, 2l)

    for (j, (x₁, x₂)) ∈ enumerate(zip(f₁, f₂))
        z = ζ(T, 2l, j)

        (f[j], f[j + l]) = (x₁ + z * x₂, x₁ - z * x₂)
    end

    f
end

function split_dft(f::AbstractVector{T}) where {T}
    l = length(f) ÷ 2

    (f₁, f₂) = (Vector{T}(undef, l) for _ ∈ 1:2)

    for j ∈ 1:l
        (c, z) = (one_half(T), ζ(T, 2l, j; inv = true))
        (x, y) = (f[begin + j - 1], f[begin + l + j - 1])

        (f₁[j], f₂[j]) = (c * (x + y), c * z * (x - y))
    end

    (f₁, f₂)
end

function gramdata(f, g, Ring = F0{Float64})
    (f₊, g₊) = dft.(Ring.([f, g]))
    (f₋, g₋) = conj.([f₊, g₊])

    (f₊, f₋, g₊, g₋, f₊ .* f₋ .+ g₊ .* g₋)
end

end # module
