import ..Utilities: KAT

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "Falcon_KAT",
    "KAT for Falcon (Specification v1.2)",
    id ->
        "https://raw.githubusercontent.com/erich-9/PQC-KAT/main/Falcon/falcon$(id)-KAT.rsp",
    [
        (;
            id = "512",
            level = :Level1,
            hash = "dd75c946fdedef4ec46a2bee7e10c65c9126f1a839b9ced6921fd45f7354b5cd",
        ),
        (;
            id = "1024",
            level = :Level5,
            hash = "036a0bf5260573cec44977284dfef756cd1143db9961b981bd1fb55828acb20d",
        ),
    ],
)

for kat ∈ kats
    @eval X = Falcon.$(kat.level)

    @testset "Falcon.$(kat.level): KAT.$(kat.id)" begin
        for t ∈ kat.file

            # The specification is not sufficient to reproduce the KAT.
            #
            # The C reference implementation derives its pseudorandom bytestream in a
            # somewhat intricate manner. For sampling, the bytes are taken from AES256CTR,
            # fed into SHAKE256 whose output is then used to seed a ChaCha20-based PRNG.

            length_smsig = NistyPQC.Utilities.bytes2int(t["sm"][begin:(begin + 1)])
            length_pad = X.lengths.sig - X.lengths.salt - length_smsig

            header = 0x30 + UInt8(X.lg_n)
            salt = t["sm"][(begin + 2):(begin + 2 + X.lengths.salt - 1)]
            smsig = t["sm"][(begin + 2 + X.lengths.salt + t["mlen"]):end]

            if length_pad ≥ 0
                sig₁ = [header; salt; smsig[(begin + 1):end]; zeros(UInt8, length_pad)]
                @test X.verify_signature(t["msg"], sig₁, t["pk"])
            end

            sig₂ = X.sign_message(t["msg"], t["sk"]; salt)
            @test X.verify_signature(t["msg"], sig₂, t["pk"])
        end
    end
end
