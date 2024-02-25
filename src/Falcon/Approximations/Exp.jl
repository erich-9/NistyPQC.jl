module Exp

function polyapprox_of_2ᵅexp()
    # probably computed with the floating-point minimax procedure of https://www.sollya.org/
    (
        α = 63,
        coeffs = [
            0x00000004741183a3,
            0x00000036548cfc06,
            0x0000024fdcbf140a,
            0x0000171d939de045,
            0x0000d00cf58f6f84,
            0x000680681cf796e3,
            0x002d82d8305b0fea,
            0x011111110e066fd0,
            0x0555555555070f00,
            0x155555555581ff00,
            0x400000000002b400,
            0x7fffffffffff4800,
            0x8000000000000000,
        ],
    )
end

end # module
