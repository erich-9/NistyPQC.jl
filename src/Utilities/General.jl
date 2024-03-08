module General

function peel(iter)
    Iterators.peel(iter)
end

function peel(iter, n::Integer)
    values = Vector{eltype(iter)}(undef, n)
    state = undef

    y = iterate(iter)
    i = 1
    while true
        if y === nothing
            i -= 1
            break
        end

        (value, state) = y
        @inbounds values[i] = value

        if i < n
            i += 1
            y = iterate(iter, state)
        else
            break
        end
    end

    if i < n
        resize!(values, i)
    end

    (values, state === undef ? iter : Iterators.rest(iter, state))
end

function peel(iter, sizes::Vector{<:Integer})
    res = Vector()
    for l ∈ sizes
        (values, iter) = peel(iter, l)
        push!(res, values)
    end
    res
end

function split_equally(v, chunks)
    Iterators.partition(v, length(v) ÷ chunks)
end

end # module
