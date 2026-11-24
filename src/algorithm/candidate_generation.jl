# Nếu một tập con không phổ biến thì ứng viên cũng không thể phổ biến.
function has_infrequent_subset(candidate_itemset::Itemset,
                               previous_frequent_itemsets::Set{Itemset})::Bool
    for removed_position in eachindex(candidate_itemset)
        subset_items = Int[]
        for position in eachindex(candidate_itemset)
            if position != removed_position
                push!(subset_items, candidate_itemset[position])
            end
        end
        if !(Tuple(subset_items) in previous_frequent_itemsets)
            return true
        end
    end
    return false
end

# Ghép hai tập phổ biến có cùng phần đầu, rồi kiểm tra các tập con.
function generate_candidates(previous_frequent_itemsets::Vector{Itemset})::Vector{Itemset}
    candidates = Itemset[]
    sorted_itemsets = sort(unique(previous_frequent_itemsets))
    frequent_lookup = Set{Itemset}(sorted_itemsets)

    for first_position in eachindex(sorted_itemsets)
        first_itemset = sorted_itemsets[first_position]
        for second_position in (first_position + 1):length(sorted_itemsets)
            second_itemset = sorted_itemsets[second_position]
            if length(first_itemset) != length(second_itemset)
                continue
            end

            # Ví dụ: (1, 2) và (1, 3) có cùng phần đầu (1,).
            if first_itemset[1:end-1] != second_itemset[1:end-1]
                continue
            end
            if first_itemset[end] >= second_itemset[end]
                continue
            end

            candidate = (first_itemset..., second_itemset[end])
            if !has_infrequent_subset(candidate, frequent_lookup)
                push!(candidates, candidate)
            end
        end
    end
    return candidates
end

# Hai tập sinh của (1, 2, 3) là (1, 2) và (1, 3).
# Bỏ item cuối để có tập thứ nhất, bỏ item áp cuối để có tập thứ hai.
function generating_subsets(candidate::Itemset)
    first_subset = candidate[1:end-1]
    second_subset = (candidate[1:end-2]..., candidate[end])
    return first_subset, second_subset
end
