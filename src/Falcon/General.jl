module General

function euclidnorm_sqr(x::AbstractArray)
    sum(abs2(v) for v ∈ Iterators.flatten(x))
end

function max_bitlength(x::AbstractArray)
    Base.top_set_bit(maximum(abs.(extrema(Iterators.flatten(x)))))
end

function polymul(f::AbstractVector{T}, g::AbstractVector{T}, trunc = true) where {T}
    l = length(f)

    res = Vector{T}(undef, 2l)

    @inbounds if l ≤ 32 # use standard multiplication
        res .= 0
        for k ∈ 0:(l - 1)
            for i ∈ 0:k
                res[begin + k] += f[begin + i] * g[begin + k - i]
            end
        end
        for k ∈ l:(2l - 2)
            for i ∈ (k - l + 1):(l - 1)
                res[begin + k] += f[begin + i] * g[begin + k - i]
            end
        end
    else # use Karatsuba multiplication
        m = l ÷ 2

        (f₁, f₂) = (f[begin:(end - m)], f[(begin + m):end])
        (g₁, g₂) = (g[begin:(end - m)], g[(begin + m):end])

        h₁ = res[begin:(end - l)] = polymul(f₁, g₁, false)
        h₂ = res[(begin + l):end] = polymul(f₂, g₂, false)

        res[(begin + m):(end - m)] .+= polymul(f₁ .+ f₂, g₁ + g₂, false) .- (h₁ .+ h₂)
    end

    @inbounds if trunc
        res = res[begin:(end - l)] - res[(begin + l):end]
    end

    res
end

function polymul_x!(f)
    f[end] *= -1
    circshift!(f, 1)
    f
end

end # module
