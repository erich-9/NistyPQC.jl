import ..Utilities: KAT, NistDRBG

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "BIKE_KAT",
    "KAT for BIKE (round 4)",
    id ->
        "https://github.com/awslabs/bike-kem/raw/a4e85f1308d18372f722b942391485411a612edf/tests/kats/$(id).kat",
    [
        (;
            id = "BIKE_L1",
            level = :Level1,
            hash = "b87120db2b3d9a5e03633d92e2a3e59a7a9ea51ff71342a85d4be02a5e057f93",
        ),
        (;
            id = "BIKE_L3",
            level = :Level3,
            hash = "5595ca0cf2d56125ea22ad2ce2c90e72dddb4c32af63f2ba6887b75a47a71028",
        ),
        (;
            id = "BIKE_L5",
            level = :Level5,
            hash = "8c3a6e9fae8134c8ffed9d5c06f6dbe24ee16d3b28f467dc907a251d0d13b386",
        ),
    ],
)

for kat ∈ kats
    @eval X = BIKE.$(kat.level)

    @testset "BIKE.$(kat.level): KAT.$(kat.id)" begin
        for t ∈ kat.file
            h_bytes = t["sk"][(4X.w + 1):(4X.w + 2X.r_bytes)]
            σ = t["sk"][(end - X.ℓ + 1):end]

            NistyPQC.rng = NistDRBG.AES256CTR(t["seed"])

            (; ek, dk) = X.generate_keys()
            @test ek == t["pk"]
            @test dk == [h_bytes; σ]

            (; K, c) = X.encapsulate_secret(t["pk"])
            @test c == t["ct"]
            @test K == t["ss"]

            K = X.decapsulate_secret(t["ct"], dk)
            @test K == t["ss"]
        end
    end
end
