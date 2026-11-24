# Đếm support của từng item và tạo C̃1: mỗi TID giữ các itemset đơn.
function build_level_one(transactions::Transactions, minimum_support_count::Int)
    item_support_counts = MiningResult()
    candidate_records = Dict{Int, Vector{Itemset}}()

    for (transaction_id, transaction) in enumerate(transactions)
        record = Itemset[]
        for item in transaction
            itemset = (item,)
            item_support_counts[itemset] = get(item_support_counts, itemset, 0) + 1
            push!(record, itemset)
        end
        candidate_records[transaction_id] = record
    end

    frequent_itemsets = MiningResult()
    for (itemset, support_count) in item_support_counts
        if support_count >= minimum_support_count
            frequent_itemsets[itemset] = support_count
        end
    end
    return frequent_itemsets, candidate_records
end

# Tạo C̃k từ C̃k-1. Không cần đọc lại giao dịch gốc.
function build_candidate_records(
    previous_candidate_records::Dict{Int, Vector{Itemset}},
    candidate_itemsets::Vector{Itemset}
)
    candidate_support_counts = MiningResult()
    current_candidate_records = Dict{Int, Vector{Itemset}}()

    # Tính hai tập sinh một lần cho mỗi candidate, trước khi duyệt các TID.
    candidate_generators = Dict{Itemset, Tuple{Itemset, Itemset}}()
    for candidate in candidate_itemsets
        candidate_support_counts[candidate] = 0
        candidate_generators[candidate] = generating_subsets(candidate)
    end

    for (transaction_id, previous_itemsets) in previous_candidate_records
        previous_lookup = Set{Itemset}(previous_itemsets)
        matching_candidates = Itemset[]

        # Basic kiểm tra lần lượt mọi candidate trong mỗi bản ghi.
        for candidate in candidate_itemsets
            first_subset, second_subset = candidate_generators[candidate]
            if first_subset in previous_lookup && second_subset in previous_lookup
                push!(matching_candidates, candidate)
                candidate_support_counts[candidate] += 1
            end
        end

        # TID không còn ứng viên thì không cần giữ ở cấp sau.
        if !isempty(matching_candidates)
            current_candidate_records[transaction_id] = matching_candidates
        end
    end
    return candidate_support_counts, current_candidate_records
end

# Tìm L1, sinh Ck, đếm support và lọc Lk cho đến khi hết ứng viên.
function mine_apriori_tid(transactions::Transactions, minimum_support_count::Int)::MiningResult
    validate_mining_input(transactions, minimum_support_count)
    all_frequent_itemsets, previous_records = build_level_one(transactions, minimum_support_count)
    previous_frequent_itemsets = collect(keys(all_frequent_itemsets))

    while !isempty(previous_frequent_itemsets)
        candidates = generate_candidates(previous_frequent_itemsets)
        if isempty(candidates)
            break
        end

        support_counts, current_records = build_candidate_records(previous_records, candidates)
        current_frequent_itemsets = Itemset[]
        for (itemset, support_count) in support_counts
            if support_count >= minimum_support_count
                all_frequent_itemsets[itemset] = support_count
                push!(current_frequent_itemsets, itemset)
            end
        end
        previous_records = current_records
        previous_frequent_itemsets = current_frequent_itemsets
    end
    return all_frequent_itemsets
end
