import ..Utilities: KAT, NistDRBG

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "MLKEM_KAT",
    "KAT for FIPS-203 (draft)",
    id -> "https://raw.githubusercontent.com/erich-9/PQC-KAT/main/MLKEM/kat_$(id).rsp",
    [
        (;
            id = "MLKEM_512",
            category = :Category1,
            hash = "0a95fa882dbc030b8fc60ec74ea735a0a0a9856a0ae4f7f70a90cb8c96aaeef2",
        ),
        (;
            id = "MLKEM_768",
            category = :Category3,
            hash = "0ded7a50bb86e47899b8aeb06a2a4131cf384d1bd73bd5c4be288dda0c6e7710",
        ),
        (;
            id = "MLKEM_1024",
            category = :Category5,
            hash = "11c87033940b32caf3a3db2033b1e24fbe0f0c5b9aa186fa47ed07e11507a757",
        ),
    ],
)

for kat ∈ kats
    @eval X = MLKEM.$(kat.category)

    @testset "MLKEM.$(kat.category): KAT.$(kat.id)" begin
        for t ∈ kat.file
            NistyPQC.with_rng(NistDRBG.AES256CTR(t["seed"])) do
                (; ek, dk) = X.generate_keys()
                @test ek == t["pk"]
                @test dk == t["sk"]

                (; K, c) = X.encapsulate_secret(t["pk"])
                @test c == t["ct"]
                @test K == t["ss"]

                K = X.decapsulate_secret(t["ct"], t["sk"])
                @test K == t["ss"]

                K = X.decapsulate_secret(t["ct_n"], t["sk"])
                @test K == t["ss_n"]
            end
        end
    end
end
