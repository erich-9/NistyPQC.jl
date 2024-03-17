import ..Utilities: KAT, NistDRBG

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "MLDSA_KAT",
    "KAT for FIPS-204 (draft)",
    id -> "https://raw.githubusercontent.com/erich-9/PQC-KAT/main/MLDSA/kat_$(id).rsp",
    [
        (;
            id = "MLDSA_44_det",
            category = :Category2,
            randomize = false,
            hash = "f6ef6af32424482d783b3dff9dce74ed56a90feb9c3329991683830dd72ce29e",
        ),
        (;
            id = "MLDSA_44_hedged",
            category = :Category2,
            randomize = true,
            hash = "42d07874fc093c03bef2a8cdb83946fca9702b48345a93675fef3bfb1b05673b",
        ),
        (;
            id = "MLDSA_65_det",
            category = :Category3,
            randomize = false,
            hash = "57b5a9baecfd84deacf7504738aabea3fbe48c0207320d23c198d7ad46c9c982",
        ),
        (;
            id = "MLDSA_65_hedged",
            category = :Category3,
            randomize = true,
            hash = "25b2d57c3e4c494c639394ba520484df4425c4bc758e52ff7a2c25442f187d95",
        ),
        (;
            id = "MLDSA_87_det",
            category = :Category5,
            randomize = false,
            hash = "8d5880cf76c7a7c703e35ff41633f0185aba0d6977f713b12353408dee46eb8f",
        ),
        (;
            id = "MLDSA_87_hedged",
            category = :Category5,
            randomize = true,
            hash = "d63cfd2bf9677e568489a14b64b50eda7d085026c6fffa42ae846058cf8f89e9",
        ),
    ],
)

for kat ∈ kats
    @eval X = MLDSA.$(kat.category)

    @testset "MLDSA.$(kat.category): KAT.$(kat.id)" begin
        for t ∈ kat.file
            NistyPQC.set_rng(NistDRBG.AES256CTR(t["seed"])) do
                msg = t["msg"]

                (; sk, pk) = X.generate_keys()
                sig = X.sign_message(msg, sk; randomize = kat.randomize)

                @test t["sk"] == sk
                @test t["pk"] == pk
                @test t["sm"] == vcat(sig, t["msg"])
            end
        end
    end
end
