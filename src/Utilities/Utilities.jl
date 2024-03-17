module Utilities

include("General.jl")
include("Bits.jl")
include("Hashing.jl")

import .General: peel, split_equally
import .Bits: bits2bytes, bytes2bits, bits2revbytes, revbytes2bits
import .Bits: bytes2int, int2bytes, int2bytes!, int2lebytes
import .Bits: bits2uint, bits2int, int2bits, revbits2uint, revbits2int, int2revbits
import .Hashing: mgf1

end # module
