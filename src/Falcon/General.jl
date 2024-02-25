module General

function euclidnorm_sqr(x::AbstractArray)
    sum(abs2(v) for v ∈ Iterators.flatten(x))
end

function max_bitlength(x::AbstractArray)
    Base.top_set_bit(maximum(abs.(extrema(Iterators.flatten(x)))))
end

end # module
