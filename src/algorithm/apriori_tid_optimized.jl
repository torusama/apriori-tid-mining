# Đếm support từng item, sau đó gán ID số liên tiếp cho các item phổ biến.
function optimized_level_one(transactions::Transactions, minimum_support_count::Int)
    item_support_counts = Dict{Int, Int}()
    for transaction in transactions
        for item in transaction
            item_support_counts[item] = get(item_support_counts, item, 0) + 1
        end
    end

    frequent_items = Int[]
    for (item, support_count) in item_support_counts
        if support_count >= minimum_support_count
            push!(frequent_items, item)
        end
    end
    sort!(frequent_items)

    item_to_identifier = Dict{Int, Int}()
    frequent_itemsets = Itemset[]
    frequent_support_counts = Int[]
    for (item_identifier, item) in enumerate(frequent_items)
        item_to_identifier[item] = item_identifier
        push!(frequent_itemsets, (item,))
        push!(frequent_support_counts, item_support_counts[item])
    end

    candidate_records = Vector{Int}[]
    for transaction in transactions
        current_record = Int[]
        for item in transaction
            if haskey(item_to_identifier, item)
                push!(current_record, item_to_identifier[item])
            end
        end
        if !isempty(current_record)
            push!(candidate_records, current_record)
        end
    end
    return frequent_itemsets, frequent_support_counts, candidate_records
end

# Lập chỉ mục candidate theo ID của tập sinh thứ nhất.
# Ví dụ (1, 2, 3) có hai tập sinh là (1, 2) và (1, 3).
function count_optimized_candidates(
    previous_itemsets::Vector{Itemset},
    previous_records::Vector{Vector{Int}},
    candidates::Vector{Itemset}
)
    itemset_to_identifier = Dict{Itemset, Int}()
    candidates_by_first_generator = Vector{Tuple{Int, Int}}[]
    for (itemset_identifier, itemset) in enumerate(previous_itemsets)
        itemset_to_identifier[itemset] = itemset_identifier
        push!(candidates_by_first_generator, Tuple{Int, Int}[])
    end

    for (candidate_identifier, candidate) in enumerate(candidates)
        first_generator, second_generator = generating_subsets(candidate)
        first_identifier = itemset_to_identifier[first_generator]
        second_identifier = itemset_to_identifier[second_generator]
        push!(candidates_by_first_generator[first_identifier], (second_identifier, candidate_identifier))
    end

    # Lưu số thứ tự bản ghi gần nhất chứa từng itemset.
    # Nhờ vậy không cần xóa mảng đánh dấu sau mỗi giao dịch.
    last_seen_record = zeros(Int, length(previous_itemsets))
    candidate_support_counts = zeros(Int, length(candidates))
    current_records = Vector{Int}[]
    for (record_number, previous_record) in enumerate(previous_records)
        # ID được tạo từ chỉ mục hợp lệ của cấp trước.
        @inbounds for itemset_identifier in previous_record
            last_seen_record[itemset_identifier] = record_number
        end

        current_record = Int[]
        @inbounds for first_identifier in previous_record
            for (second_identifier, candidate_identifier) in candidates_by_first_generator[first_identifier]
                if last_seen_record[second_identifier] == record_number
                    candidate_support_counts[candidate_identifier] += 1
                    push!(current_record, candidate_identifier)
                end
            end
        end
        if !isempty(current_record)
            push!(current_records, current_record)
        end
    end
    return candidate_support_counts, current_records
end

function mine_apriori_tid_optimized(
    transactions::Transactions,
    minimum_support_count::Int
)::MiningResult
    validate_mining_input(transactions, minimum_support_count)
    previous_itemsets, support_counts, candidate_records = optimized_level_one(transactions, minimum_support_count)
    results = MiningResult()
    for (itemset_identifier, itemset) in enumerate(previous_itemsets)
        results[itemset] = support_counts[itemset_identifier]
    end
    frequent_itemsets = previous_itemsets

    while length(frequent_itemsets) >= 2
        candidates = generate_candidates(frequent_itemsets)
        if isempty(candidates)
            break
        end
        support_counts, candidate_records = count_optimized_candidates(previous_itemsets, candidate_records, candidates)
        frequent_itemsets = Itemset[]
        for (candidate_identifier, candidate) in enumerate(candidates)
            if support_counts[candidate_identifier] >= minimum_support_count
                results[candidate] = support_counts[candidate_identifier]
                push!(frequent_itemsets, candidate)
            end
        end

        # Chỉ giữ ID của candidate phổ biến. ID vẫn trỏ vào candidates,
        # không trỏ vào danh sách frequent_itemsets ngắn hơn.
        # filter! xóa trực tiếp phần tử không đạt ngưỡng, không tạo bản sao.
        for record in candidate_records
            filter!(candidate_identifier -> support_counts[candidate_identifier] >= minimum_support_count, record)
        end
        filter!(record -> !isempty(record), candidate_records)
        previous_itemsets = candidates
    end
    return results
end
