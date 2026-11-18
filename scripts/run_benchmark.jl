using FrequentItemsetMining
using Random
using SHA
using Statistics
using TOML

const BENCHMARK_PROJECT = dirname(@__DIR__)
for file in ("benchmark.jl", "memory_profile.jl", "scalability.jl")
    include(joinpath(BENCHMARK_PROJECT, "src", "evaluation", file))
end

function run_benchmark(data_dir, output_dir, jar, config_path)
    config = TOML.parsefile(config_path)
    repetitions = config["repetitions"]
    repetitions > 0 || throw(ArgumentError("Repetitions must be positive."))
    isfile(jar) || throw(ArgumentError("SPMF JAR does not exist: $jar"))
    mkpath(output_dir)
    saved_config = joinpath(output_dir, "config.toml")
    if abspath(config_path) != abspath(saved_config)
        cp(config_path, saved_config; force = true)
    end

    open(joinpath(output_dir, "environment.txt"), "w") do io
        println(io, "Julia: ", VERSION)
        println(io, "Julia threads: ", Threads.nthreads())
        println(io, "OS and architecture: ", Sys.KERNEL, " ", Sys.ARCH)
        println(io, "CPU: ", first(Sys.cpu_info()).model)
        println(io, "Host RAM bytes: ", Sys.total_memory())
        println(io, "SPMF SHA-256: ", bytes2hex(open(sha256, jar)))
        println(io, "Java: ", chomp(read(`java --version`, String)))
        println(io, "Julia runtime: median warmed mine(), excluding file I/O and process startup")
        println(io, "SPMF runtime: median internal reported time; separate JVM for each repetition")
        println(io, "Peak RSS: fresh Julia CLI process, including startup, parsing and output")
    end

    comparisons_ok = true
    open(joinpath(output_dir, "benchmarks.csv"), "w") do measured
        open(joinpath(output_dir, "datasets.csv"), "w") do profiles
            open(joinpath(output_dir, "peak_ram.csv"), "w") do memory
                open(joinpath(output_dir, "correctness_differences.txt"), "w") do differences
                    println(measured, "dataset,minsup,minimum_support_count,implementation,runtime_ms,allocated_bytes,itemsets,reference_itemsets,exact_match,match_percent,missing,extra,wrong_support")
                    println(profiles, "dataset,transactions,distinct_items,mean_width,normalized_sha256")
                    println(memory, "dataset,minsup,implementation,peak_rss_bytes")

                    for dataset in config["datasets"]
                        name, supports = dataset["name"], dataset["minsups"]
                        input = joinpath(data_dir, name * ".txt")
                        transactions = read_transactions(input)
                        items = Set(item for transaction in transactions for item in transaction)
                        write_csv_row(profiles, name, length(transactions), length(items),
                                      mean(length, transactions), bytes2hex(open(sha256, input)))
                        for support in supports
                            println("Benchmark $name, minsup=$support")
                            threshold = calculate_minimum_support_count(support, length(transactions))
                            spmf = measure_spmf(jar, input, support, repetitions)
                            expected = spmf.result
                            write_csv_row(measured, name, support, threshold, "spmf", spmf.milliseconds,
                                          "", length(expected), length(expected), true, 100, 0, 0, 0)
                            for implementation in JULIA_IMPLEMENTATIONS
                                run = measure_mining(transactions, support, implementation, repetitions)
                                comparison = compare_results(run.result, expected)
                                differences_count = (length(comparison.missing_itemsets),
                                                     length(comparison.extra_itemsets),
                                                     length(comparison.wrong_support))
                                write_csv_row(measured, name, support, threshold, implementation,
                                              run.milliseconds, run.allocated_bytes, length(run.result),
                                              length(expected), comparison.matches,
                                              comparison.matching_percentage, differences_count...)
                                if !comparison.matches
                                    comparisons_ok = false
                                    println(differences, "$name, minsup=$support, $implementation")
                                    show(differences, comparison)
                                    println(differences)
                                end
                            end
                            flush(measured)
                        end

                        middle = supports[cld(length(supports), 2)]
                        for implementation in JULIA_IMPLEMENTATIONS
                            peak = measure_peak_rss(BENCHMARK_PROJECT, abspath(input), middle, implementation)
                            write_csv_row(memory, name, middle, implementation, peak)
                        end
                        flush(memory)
                        if name == "retail"
                            open(joinpath(output_dir, "scalability.csv"), "w") do io
                                println(io, "fraction,transactions,minsup,implementation,runtime_ms,itemsets")
                                measure_scalability(io, transactions, config["retail_fractions"],
                                                    config["seed"], middle, repetitions)
                            end
                        end
                    end
                end
            end
        end
    end

    open(joinpath(output_dir, "transaction_width.csv"), "w") do io
        println(io, "width,transactions,items,minsup,implementation,runtime_ms,itemsets")
        measure_transaction_width(io, config["synthetic_transactions"], config["synthetic_items"],
                                  config["synthetic_widths"], config["seed"],
                                  config["synthetic_minsup"], repetitions)
    end
    comparisons_ok || error("Some of the benchmark results differ from SPMF. See correctness_differences.txt.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    2 <= length(ARGS) <= 4 || error("Usage: run_benchmark.jl DATA_DIR OUTPUT_DIR [SPMF_JAR] [CONFIG]")
    jar = length(ARGS) >= 3 ? ARGS[3] : joinpath(BENCHMARK_PROJECT, "tools", "spmf.jar")
    config = length(ARGS) == 4 ? ARGS[4] : joinpath(BENCHMARK_PROJECT, "configs", "benchmark.toml")
    run_benchmark(ARGS[1], ARGS[2], jar, config)
end
