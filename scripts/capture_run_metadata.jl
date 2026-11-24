using Dates
using SHA
using TOML

# Capture the files that determine mining and measurement behavior.
function capture_run_metadata(output_directory)
    project = dirname(@__DIR__)
    files = ["Project.toml", "Manifest.toml", "configs/benchmark.toml",
             "src/FrequentItemsetMining.jl", "src/structures.jl", "src/utils.jl",
             "scripts/run_benchmark.jl", "scripts/measure_retail_processes.jl", "scripts/run_market_basket.jl",
             "scripts/visual_pipeline.jl"]
    for directory in ("src/algorithm", "src/applications", "src/evaluation")
        append!(files, [joinpath(directory, name) for name in readdir(joinpath(project, directory))
                        if endswith(name, ".jl")])
    end
    hashes = Dict(file => bytes2hex(open(sha256, joinpath(project, file))) for file in sort!(unique(files)))
    fingerprint = bytes2hex(sha256(join(["$file $(hashes[file])" for file in sort!(collect(keys(hashes)))], '\n')))
    revision = strip(read(Cmd(`git rev-parse HEAD`; dir = project), String))
    manifest = Dict(
        "captured_utc" => string(now(UTC)),
        "source_revision" => revision,
        "source_fingerprint_sha256" => fingerprint,
        "julia_version" => string(VERSION),
        "julia_threads" => Threads.nthreads(),
        "seed" => 42,
        "benchmark_config" => "configs/benchmark.toml",
        "source_files_sha256" => hashes,
        "dataset_checksums" => "benchmark/datasets.csv",
        "test_log" => "../correctness/final-tests.txt",
        "runtime_scope" => "Julia median warmed mine(); SPMF median internal reported time",
        "memory_scope" => "Peak RSS of a fresh Julia CLI, including input and output"
    )
    mkpath(output_directory)
    open(joinpath(output_directory, "run_manifest.toml"), "w") do io
        TOML.print(io, manifest; sorted = true)
    end
    println("Source fingerprint: $fingerprint")
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) == 1 || error("Usage: capture_run_metadata.jl OUTPUT_DIRECTORY")
    capture_run_metadata(ARGS[1])
end
