module Matrices

function semisystematic_form!(x::Vector{BitVector}, μ, ν)
    r = length(x)
    rref!(x) == r || return nothing
    p = map(i -> findfirst(isone, x[i]) - firstindex(x[i]) + 1, 1:r)
    ((r == μ || p[r - μ] == r - μ) && p[r] ≤ r - μ + ν) || return nothing
    last(p, μ)
end

function rref!(x::Vector{BitVector})
    (r, r_max) = (firstindex(x), lastindex(x))
    (c, c_max) = (firstindex(first(x)), lastindex(first(x)))
    while r ≤ r_max && c ≤ c_max
        r₀ = r
        while r₀ ≤ r_max && iszero(x[r₀][c])
            r₀ += 1
        end
        if r₀ ≤ r_max
            swap!(x, r₀, r)
            z = x[r][c]
            for i ∈ eachindex(x)
                z = x[i][c]
                if i != r && !iszero(z)
                    x[i] .⊻= z .& x[r]
                end
            end
            r += 1
        end
        c += 1
    end
    r - firstindex(x)
end

function rref!(x::AbstractMatrix)
    (r, r_max) = (firstindex(x, 1), lastindex(x, 1))
    (c, c_max) = (firstindex(x, 2), lastindex(x, 2))
    while r ≤ r_max && c ≤ c_max
        r₀ = r
        while r₀ ≤ r_max && iszero(x[r₀, c])
            r₀ += 1
        end
        if r₀ ≤ r_max
            swap_rows!(x, r₀, r)
            z = x[r, c]
            if !isone(z)
                x[r, c:c_max] *= inv(z)
            end
            for i ∈ axes(x, 1)
                z = x[i, c]
                if i != r && !iszero(z)
                    for j ∈ c:c_max
                        x[i, j] -= z * x[r, j]
                    end
                end
            end
            r += 1
        end
        c += 1
    end
    r - firstindex(x, 1)
end

function swap!(x::AbstractVector, i₁::Integer, i₂::Integer)
    if i₁ != i₂
        (x[i₁], x[i₂]) = (x[i₂], x[i₁])
    end
end

function swap_rows!(x::AbstractMatrix, i₁::Integer, i₂::Integer)
    i₁ != i₂ || return
    for j ∈ axes(x, 2)
        (x[i₁, j], x[i₂, j]) = (x[i₂, j], x[i₁, j])
    end
end

function swap_cols!(x::AbstractMatrix, j₁::Integer, j₂::Integer)
    j₁ != j₂ || return
    for i ∈ axes(x, 1)
        (x[i, j₁], x[i, j₂]) = (x[i, j₂], x[i, j₁])
    end
end

end # module
