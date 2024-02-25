module General

function base_2ᵇ(bytes, b, out_len, IntType = Int)
    # @assert out_len * b ≤ 8 * length(bytes)

    i = 1
    b̂ = 0
    t = zero(IntType)
    ys = Vector{IntType}(undef, out_len)
    for j ∈ 1:out_len
        while b̂ < b
            t = (t << 8) + bytes[i]
            i += 1
            b̂ += 8
        end
        b̂ -= b
        ys[j] = (t >> b̂) & (oneunit(IntType) << b - 1)
    end
    ys
end

end # General
