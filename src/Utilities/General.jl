module General

function split_equally(v, chunks)
    Iterators.partition(v, length(v) ÷ chunks)
end

end # module
