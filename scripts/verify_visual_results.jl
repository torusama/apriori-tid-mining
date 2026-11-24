using FrequentItemsetMining
using TOML
include(joinpath(@__DIR__, "..", "src", "applications", "visual_patterns.jl"))

function verify_visual_results(directory)
    transactions = read_visual_transactions(joinpath(directory, "flowers_spmf.txt"))
    summary = TOML.parsefile(joinpath(directory, "dataset_summary.toml"))
    length(transactions) == summary["images"] || error("Image denominator mismatch.")
    count(isempty, transactions) == summary["empty_transactions"] || error("Empty image count mismatch.")
    verified = 0
    for minimum_support in (0.7, 0.8, 0.9)
        threshold = calculate_minimum_support_count(minimum_support, length(transactions))
        itemsets = read_itemsets(joinpath(directory, "itemsets_$(minimum_support).txt"))
        for (itemset, support) in itemsets
            independent = count(transaction -> all(item -> item in transaction, itemset), transactions)
            independent == support >= threshold || error("Support mismatch for $itemset.")
            verified += 1
        end
        expected = mine_visual_transactions(transactions, minimum_support; implementation = :basic)
        expected == itemsets || error("Basic and saved Optimized differ at minsup $minimum_support.")
    end
    report = Dict("images" => length(transactions), "verified_itemset_rows" => verified,
                  "all_support_counts_match" => true, "basic_matches_optimized" => true)
    open(joinpath(directory, "verification.toml"), "w") do io
        TOML.print(io, report; sorted = true)
    end
    println(report)
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) == 1 || error("Usage: verify_visual_results.jl RESULT_DIRECTORY")
    verify_visual_results(ARGS[1])
end
