const JULIA_IMPLEMENTATIONS = (:basic, :optimized)

function measure_mining(transactions, minimum_support, implementation, repetitions)
    mine(transactions; minimum_support, implementation)
    milliseconds = Float64[]
    allocated_bytes = Int[]
    result = MiningResult()
    for _ in 1:repetitions
        GC.gc()
        measurement = @timed mine(transactions; minimum_support, implementation)
        push!(milliseconds, 1000 * measurement.time)
        push!(allocated_bytes, measurement.bytes)
        result = measurement.value
    end
    return (; milliseconds = median(milliseconds), allocated_bytes = round(Int, median(allocated_bytes)), result)
end

function measure_spmf(jar, input, minimum_support, repetitions)
    mktempdir() do directory
        milliseconds = Int[]
        result = MiningResult()
        for repetition in 1:repetitions
            log_path = joinpath(directory, "spmf.log")
            output_path = joinpath(directory, "output-$repetition.txt")
            result = open(log_path, "w") do log
                run_spmf(jar, input, output_path, minimum_support; output_stream = log)
            end
            stats = read(log_path, String)
            duration = match(r"Total time\s*~\s*(\d+)\s*ms", stats)
            isnothing(duration) && error("SPMF runtime missing from its statistics.")
            push!(milliseconds, parse(Int, duration.captures[1]))
        end
        return (; milliseconds = median(milliseconds), result)
    end
end

function write_csv_row(io::IO, values...)
    println(io, join(values, ','))
end
