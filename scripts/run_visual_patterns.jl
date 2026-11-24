using FrequentItemsetMining
include(joinpath(@__DIR__, "..", "src", "applications", "visual_patterns.jl"))

# Chạy Apriori-TID của nhóm và lưu support count của từng tập phổ biến.
function run_visual_mining(arguments)
    if length(arguments) != 4
        error("Usage: julia --project=. scripts/run_visual_patterns.jl TRANSACTIONS OUTPUT MINSUP basic|optimized")
    end
    transaction_path, output_path, minimum_support_text, implementation_text = arguments
    transactions = read_visual_transactions(transaction_path)
    minimum_support = parse(Float64, minimum_support_text)
    implementation = Symbol(implementation_text)
    elapsed_time = @elapsed itemsets = mine_visual_transactions(
        transactions, minimum_support; implementation = implementation
    )
    write_itemsets(output_path, itemsets)
    println("transactions=$(length(transactions)) patterns=$(length(itemsets)) seconds=$(elapsed_time)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_visual_mining(ARGS)
end
