using FrequentItemsetMining: run_market_basket

if abspath(PROGRAM_FILE) == @__FILE__
    3 <= length(ARGS) <= 6 || error(
        "Usage: run_market_basket.jl DATA LABELS OUTPUT_DIR [MINSUP] [MINCONF] [basic|optimized]"
    )
    minimum_support = length(ARGS) >= 4 ? parse(Float64, ARGS[4]) : 0.01
    minconf = length(ARGS) >= 5 ? parse(Float64, ARGS[5]) : 0.4
    implementation = length(ARGS) == 6 ? Symbol(ARGS[6]) : :optimized
    println(run_market_basket(ARGS[1:3]...; minimum_support, minconf, implementation))
end
