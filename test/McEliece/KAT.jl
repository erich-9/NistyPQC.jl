import ..Utilities: KAT, NistDRBG
import ..run_all

kats = KAT.register_files(
    KAT.NISTFormattedFile,
    "McEliece_KAT",
    "KAT for Classic McEliece (round 4)",
    id ->
        "https://raw.githubusercontent.com/erich-9/PQC-KAT/main/McEliece/kat_mceliece$(id).rsp",
    [
        (;
            id = "348864",
            category = :Category1,
            hash = "76351ed2e95a616ca76230bac579cead21012d89181c7398381d0bbe904ab92c",
        ),
        (;
            id = "348864f",
            category = :Category1f,
            hash = "d0d5ea348a181740862dcc8476ff7d00ce44d1c6e36b2145289d97f580f2cd7d",
        ),
        (;
            id = "460896",
            category = :Category3,
            hash = "fd785edfe1b721fb24fe159cb9f30cc17daec3d188d59a4bf47a83388880192e",
        ),
        (;
            id = "460896f",
            category = :Category3f,
            hash = "552da50baff2666db7b64486c88da4e2b65b25c3d5424be682ca08ffce15a356",
        ),
        (;
            id = "6688128",
            category = :Category5A,
            hash = "3f926328959729c61a11b11ab6326246a42d9b3e76943bba2625342ea33723e2",
        ),
        (;
            id = "6688128f",
            category = :Category5Af,
            hash = "7b64c9882a00bc984e0ca9d3748d0b1bd9215d1bcf921643ee88d28d539303d8",
        ),
        (;
            id = "6960119",
            category = :Category5B,
            hash = "e4d608fa9795c1a1704709ab9df3940ae1dbf0f708cc0dbdf76c8f3173088e46",
        ),
        (;
            id = "6960119f",
            category = :Category5Bf,
            hash = "d6d3e929ff505108fd545d14df5f5bac234cd6d882f0eed3fd628f122e3093c6",
        ),
        (;
            id = "8192128",
            category = :Category5C,
            hash = "beb28fc0d1555a0028afeb6ebc72b8337f424a826be3d49b47759b8bda50db90",
        ),
        (;
            id = "8192128f",
            category = :Category5Cf,
            hash = "3fdb40d47705829c16de4fb5a81f7c095eb4dadc306cfc2c89eff2f483c42402",
        ),
    ],
)

for kat ∈ kats
    @eval X = McEliece.$(kat.category)

    if !run_all && X.category_number == 5 && !X.fast_variant
        continue
    end

    @testset "McEliece.$(kat.category): KAT.$(kat.id)" begin
        for t ∈ kat.file
            NistyPQC.set_rng(NistDRBG.AES256CTR(t["seed"])) do
                (; ek, dk) = X.generate_keys()
                @test ek == t["pk"]
                @test dk == t["sk"]

                (; K, c) = X.encapsulate_secret(t["pk"])
                @test c == t["ct"]
                @test K == t["ss"]

                K = X.decapsulate_secret(t["ct"], dk)
                @test K == t["ss"]
            end

            if !run_all
                break
            end
        end
    end
end
