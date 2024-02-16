module General

function split_equally(v, chunksize)
    Iterators.partition(v, length(v) ÷ chunksize)
end

end # module
