module KAT

import DataDeps

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

function register_files(KATFileType, name, message, url_from_id, kat_details)
    ph = NamedTuple(k => getfield.(kat_details, k) for k ∈ [:id, :hash])

    remote_paths = url_from_id.(ph.id)
    datadep_paths = ["$name/$(basename(x))" for x ∈ remote_paths]

    DataDeps.register(DataDeps.DataDep(name, message, remote_paths, ph.hash))

    (
        (; f..., file = KATFileType(DataDeps.resolve(path, @__FILE__))) for
        (path, f) ∈ zip(datadep_paths, kat_details)
    )
end

abstract type KATFile end

struct NISTFormattedFile <: KATFile
    filename::String
end

Base.IteratorSize(::Type{NISTFormattedFile}) = Base.SizeUnknown()

function Base.iterate(kat::NISTFormattedFile)
    x = eachline(kat.filename)
    it = iterate(x)
    Base.iterate(kat, (x, it))
end

function Base.iterate(::NISTFormattedFile, state)
    if state != ()
        (x, it) = state

        y = nothing
        while true
            (line, it_state) = it

            m = match(r"^([^=\s]*)\s*=\s*([^=\s]*)$", line)

            if m !== nothing
                (k, v) = m.captures

                if k == "count"
                    if y !== nothing
                        return (y, (x, it))
                    else
                        y = Dict{String, Any}()
                    end
                elseif occursin(r"^(?:[0-9a-fA-F]{2})+$", v)
                    y[k] = hex2bytes(v)
                else
                    try
                        y[k] = parse(Int, v)
                    catch ArgumentError
                        y[k] = v
                    end
                end
            end

            it = iterate(x, it_state)

            if it === nothing
                return (y, ())
            end
        end
    end
end

end # module
