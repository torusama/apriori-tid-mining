using FrequentItemsetMining
using Statistics

include(joinpath(@__DIR__, "..", "src", "evaluation", "benchmark.jl"))

function measure_retail_worker(input_path, trial)
    transactions = read_transactions(input_path)
    for implementation in JULIA_IMPLEMENTATIONS
        measurement = measure_mining(transactions, 0.03, implementation, 3)
        write_csv_row(stdout, trial, length(transactions), 0.03, implementation,
                      measurement.milliseconds, measurement.allocated_bytes, length(measurement.result))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) == 3 && ARGS[1] == "--worker"
        measure_retail_worker(ARGS[2], parse(Int, ARGS[3]))
    else
        length(ARGS) == 2 || error("Usage: measure_retail_processes.jl RETAIL_INPUT OUTPUT_CSV")
        input_path, output_path = abspath.(ARGS)
        project = dirname(@__DIR__)
        script = @__FILE__
        mkpath(dirname(output_path))
        open(output_path, "w") do io
            println(io, "process_trial,transactions,minsup,implementation,runtime_ms,allocated_bytes,itemsets")
            for trial in 1:3
                command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$project $script --worker $input_path $trial`
                print(io, read(command, String))
                flush(io)
                println("Retail process $trial completed")
            end
        end
    end
end
