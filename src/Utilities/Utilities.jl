module Utilities

include("General.jl")
include("Bits.jl")
include("Hashing.jl")

import .General: split_equally
import .Bits: bits2bytes, bytes2bits
import .Bits: bytes2int, int2bytes, int2bytes!
import .Bits: bits2uint, bits2int, int2bits
import .Hashing: mgf1

end # module
