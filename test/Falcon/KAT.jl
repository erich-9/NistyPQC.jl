import ..Utilities: KAT, NistDRBG

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "Falcon_KAT",
    "KAT for Falcon (Specification v1.2)",
    id -> "",
    [
    # (;
    #     id = "",
    #     level = :Level1,
    #     hash = "",
    # ),
    ],
)

rng = NistyPQC.rng

for kat ∈ kats
    @eval X = Falcon.$(kat.level)

    @testset "Falcon.$(kat.level): KAT.$(kat.id)" begin
        for t ∈ kat.file
            # pk = X.PublicKey(...)
            # sk = X.SecretKey(...)
            # msg = t["msg"]

            # NistyPQC.rng = NistDRBG.AES256CTR(t["seed"])

            # (; pk, sk) = X.generate_keys()
            # sig = X.sign_message(msg, sk)

            # @test t["sk"] == ...
            # @test t["pk"] == ...
            # @test t["sm"] == vcat(sig, t["msg"])
        end
    end
end

NistyPQC.rng = rng
