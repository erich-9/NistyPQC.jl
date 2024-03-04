import ..Utilities: KAT, NistDRBG

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "SLHDSA_KAT",
    "KAT for FIPS-205 (draft)",
    id ->
        "https://github.com/mjosaarinen/slh-dsa-py/raw/bc45ee539428aa708c342ed4ada4ef7da543b2e9/kat/$(id).rsp.1",
    [
        (;
            id = "sphincs-sha2-128s-simple",
            level = :Level1s_sha2,
            hash = "a316908dec0998861b647f40213bf37cbfc2b3634b8a0a52e4503dba59bad441",
        ),
        (;
            id = "sphincs-shake-128s-simple",
            level = :Level1s_shake,
            hash = "d36999edc06c0daeaae9e6346b4b5a5ea9503387fb343bfe869c5ccd0a90c51c",
        ),
        (;
            id = "sphincs-sha2-128f-simple",
            level = :Level1f_sha2,
            hash = "d3df72bb154abaef53cc5d0dd5b4fde46a797e90e30805fff7c3e31041ab4c67",
        ),
        (;
            id = "sphincs-shake-128f-simple",
            level = :Level1f_shake,
            hash = "6452ae18c387c7816d1396b0919c824479d0ab02f91010f59d26cd405fe309b4",
        ),
        (;
            id = "sphincs-sha2-192s-simple",
            level = :Level3s_sha2,
            hash = "601be3028bf69f6c7aecfd709b95c9c778e2420b976967771203e2e824a86321",
        ),
        (;
            id = "sphincs-shake-192s-simple",
            level = :Level3s_shake,
            hash = "84644ef3f842f5939f48179bcbc1f8c0e494f5a76585c71a176547e6ef297517",
        ),
        (;
            id = "sphincs-sha2-192f-simple",
            level = :Level3f_sha2,
            hash = "f525b6569082b4335593eab8257364a5754932b2a209fc194c09ffce12bfbb16",
        ),
        (;
            id = "sphincs-shake-192f-simple",
            level = :Level3f_shake,
            hash = "7cf1ae6803f24d2fabcc2f98e77ab703fc223b6d5ddd5091658d03c13c3045b2",
        ),
        (;
            id = "sphincs-sha2-256s-simple",
            level = :Level5s_sha2,
            hash = "2b23b59d31969dbb91fb5465d26637448c53658631d9c218664e2ad1a2cb69e0",
        ),
        (;
            id = "sphincs-shake-256s-simple",
            level = :Level5s_shake,
            hash = "b399077b5c53daffd830df98dd3953b9db1903a151bc679adff314a93cf808d0",
        ),
        (;
            id = "sphincs-sha2-256f-simple",
            level = :Level5f_sha2,
            hash = "1aab628d922a489f6879e29b55e5a474c3b9d4c52b166a52e7504f69bf85057a",
        ),
        (;
            id = "sphincs-shake-256f-simple",
            level = :Level5f_shake,
            hash = "049ff342c967ee43f586052249ba3313297e6630c1095d2af869853a717f0acd",
        ),
    ],
)

rng = NistyPQC.rng

for kat ∈ kats
    @eval X = SLHDSA.$(kat.level)

    @testset "SLHDSA.$(kat.level): KAT.$(kat.id)" begin
        for t ∈ kat.file
            msg = t["msg"]

            NistyPQC.rng = NistDRBG.AES256CTR(t["seed"])

            (; pk, sk) = X.generate_keys()
            sig = X.sign_message(msg, sk)

            @test t["sk"] == sk
            @test t["pk"] == pk
            @test t["sm"] == vcat(sig, t["msg"])
        end
    end
end

NistyPQC.rng = rng
