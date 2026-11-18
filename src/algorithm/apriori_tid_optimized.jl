function optimized_level_one(transactions::Transactions, minimum_support_count::Int)
    counts = Dict{Int, Int}()
    for transaction in transactions, item in transaction
        counts[item] = get(counts, item, 0) + 1
    end

    items = sort!([item for (item, count) in counts if count >= minimum_support_count])
    item_ids = Dict(item => id for (id, item) in enumerate(items))
    records = Vector{Int}[]
    for transaction in transactions
        record = [item_ids[item] for item in transaction if haskey(item_ids, item)]
        isempty(record) || push!(records, record)
    end

    itemsets = Itemset[(item,) for item in items]
    return itemsets, [counts[item] for item in items], records
end

function count_optimized_candidates(
    previous_itemsets::Vector{Itemset},
    previous_records::Vector{Vector{Int}},
    candidates::Vector{Itemset}
)
    previous_ids = Dict(itemset => id for (id, itemset) in enumerate(previous_itemsets))
    joins_by_first = [Tuple{Int, Int}[] for _ in previous_itemsets]
    for (candidate_id, candidate) in enumerate(candidates)
        first_id = previous_ids[candidate[1:(end - 1)]]
        second_id = previous_ids[(candidate[1:(end - 2)]..., candidate[end])]
        push!(joins_by_first[first_id], (second_id, candidate_id))
    end

    marks = zeros(Int, length(previous_itemsets))
    counts = zeros(Int, length(candidates))
    current_records = Vector{Int}[]
    for (record_id, previous_record) in enumerate(previous_records)
        for itemset_id in previous_record
            marks[itemset_id] = record_id
        end

        current_record = Int[]
        # A candidate has exactly one first generator, so each record counts it at most once.
        for first_id in previous_record, (second_id, candidate_id) in joins_by_first[first_id]
            if marks[second_id] == record_id
                counts[candidate_id] += 1
                push!(current_record, candidate_id)
            end
        end
        isempty(current_record) || push!(current_records, current_record)
    end

    return counts, current_records
end

# The shared mine() entry point has already validated transactions and the threshold.
function mine_apriori_tid_optimized(
    transactions::Transactions, minimum_support_count::Int
)::MiningResult
    itemsets, counts, records = optimized_level_one(transactions, minimum_support_count)
    result = MiningResult(zip(itemsets, counts))
    frequent = itemsets

    while length(frequent) >= 2
        candidates = generate_candidates(frequent)
        isempty(candidates) && break
        counts, records = count_optimized_candidates(itemsets, records, candidates)
        frequent = Itemset[]
        for (id, itemset) in enumerate(candidates)
            if counts[id] >= minimum_support_count
                result[itemset] = counts[id]
                push!(frequent, itemset)
            end
        end

        for record in records
            filter!(id -> counts[id] >= minimum_support_count, record)
        end
        filter!(!isempty, records)
        itemsets = candidates
    end

    return result
end
