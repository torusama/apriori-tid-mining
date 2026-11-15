# Kiểm tra một candidate có tập con nào không phổ biến hay không.
#
# Ví dụ:
# Candidate = (1, 2, 3)
# Các tập con gồm (1, 2), (1, 3), (2, 3).
#
# Nếu một trong các tập con không phổ biến,
# candidate cũng không thể là tập phổ biến.
function has_infrequent_subset(
    candidate_itemset::Itemset,
    previous_frequent_itemsets::Set{Itemset}
)::Bool

    # Lần lượt loại một item để tạo các tập con.
    for removed_item_position in eachindex(candidate_itemset)

        subset_items = Int[]

        for item_position in eachindex(candidate_itemset)

            if item_position != removed_item_position
                push!(subset_items, candidate_itemset[item_position])
            end
        end

        # Đổi mảng thành Tuple để so sánh với các itemset.
        subset_itemset = Tuple(subset_items)

        # Nếu tập con không phổ biến thì trả về true.
        if !(subset_itemset in previous_frequent_itemsets)
            return true
        end
    end

    # Tất cả tập con đều phổ biến.
    return false
end


# Sinh các candidate mới từ các frequent itemsets của cấp trước.
#
# Bước 1: Ghép hai itemset có cùng phần đầu.
# Bước 2: Kiểm tra tất cả tập con của candidate.
# Bước 3: Chỉ giữ candidate vượt qua bước kiểm tra.
function generate_candidates(
    previous_frequent_itemsets::Vector{Itemset}
)::Vector{Itemset}

    candidate_itemsets = Itemset[]

    # Không có tập phổ biến thì không thể sinh ứng viên mới.
    if isempty(previous_frequent_itemsets)
        return candidate_itemsets
    end

    # Sắp xếp các tập phổ biến và loại phần tử trùng.
    sorted_frequent_itemsets = sort(unique(previous_frequent_itemsets))

    # Dùng Set để kiểm tra một itemset có phổ biến hay không.
    frequent_itemset_lookup = Set{Itemset}(sorted_frequent_itemsets)

    # Xét lần lượt từng cặp itemset.
    for first_position in eachindex(sorted_frequent_itemsets)

        first_itemset = sorted_frequent_itemsets[first_position]

        for second_position in (first_position + 1):length(sorted_frequent_itemsets)

            second_itemset = sorted_frequent_itemsets[second_position]

            # Hai tập phải có cùng số lượng item.
            if length(first_itemset) != length(second_itemset)
                continue
            end

            # Kiểm tra hai tập có cùng các item ở phần đầu hay không.
            common_prefix_length = length(first_itemset) - 1
            same_prefix = true

            for item_position in 1:common_prefix_length

                if first_itemset[item_position] != second_itemset[item_position]
                    same_prefix = false
                    break
                end
            end

            # Không ghép nếu phần đầu khác nhau.
            if !same_prefix
                continue
            end

            # Item cuối của tập thứ nhất phải nhỏ hơn tập thứ hai.
            if first_itemset[end] >= second_itemset[end]
                continue
            end

            # Tạo ứng viên bằng cách thêm item cuối của tập thứ hai.
            candidate_itemset = (
                first_itemset...,
                second_itemset[end]
            )

            # Loại candidate nếu chứa tập con không phổ biến.
            if has_infrequent_subset(
                candidate_itemset,
                frequent_itemset_lookup
            )
                continue
            end

            push!(candidate_itemsets, candidate_itemset)
        end
    end

    return candidate_itemsets
end