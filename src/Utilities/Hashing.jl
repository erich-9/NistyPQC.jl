module Hashing

function mgf1(hash_func, msg::AbstractVector{UInt8}, n::Int)
    res = Vector{UInt8}()
    counter::UInt32 = 0
    while length(res) < n
        append!(res, hash_func(vcat(msg, reinterpret(UInt8, [hton(counter)]))))
        counter += 1
    end
    res[1:n]
end

end # Hashing
