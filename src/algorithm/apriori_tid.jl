# ============================================================
# HÀM 1: build_level_one
#
# Chức năng:
# - Duyệt cơ sở dữ liệu ban đầu.
# - Đếm số giao dịch chứa từng item.
# - Tìm các frequent 1-itemsets.
# - Tạo bản ghi trung gian cấp 1 cho thuật toán Apriori-TID.
#
# Ví dụ:
# Transaction 1: [1, 2, 3]
# Transaction 2: [1, 2]
#
# Bản ghi trung gian:
# 1 => [(1,), (2,), (3,)]
# 2 => [(1,), (2,)]
# ============================================================

function build_level_one(
    transactions::Transactions,
    minimum_support_count::Int
)

    # Lưu support count của từng item đơn.
    item_support_counts = MiningResult()

    # Lưu các itemsets theo từng Transaction ID.
    previous_candidate_records = Dict{Int, Vector{Itemset}}()

    for (transaction_id, transaction) in enumerate(transactions)

        itemsets_in_transaction = Itemset[]

        for item in transaction

            # Một itemset gồm duy nhất một item.
            single_itemset = (item,)

            # Lấy số lần xuất hiện hiện tại của item.
            current_support_count = get(
                item_support_counts,
                single_itemset,
                0
            )

            # Tăng support count thêm một đơn vị.
            item_support_counts[single_itemset] = current_support_count + 1

            # Lưu itemset vào bản ghi trung gian của transaction.
            push!(itemsets_in_transaction, single_itemset)
        end

        previous_candidate_records[transaction_id] = itemsets_in_transaction
    end

    # Chỉ giữ những itemset đạt ngưỡng support.
    frequent_single_itemsets = MiningResult()

    for (itemset, support_count) in item_support_counts

        if support_count >= minimum_support_count
            frequent_single_itemsets[itemset] = support_count
        end
    end

    return frequent_single_itemsets, previous_candidate_records
end


# ============================================================
# HÀM 2: build_candidate_records
#
# Chức năng:
# - Nhận các candidate cấp hiện tại.
# - Nhận các bản ghi trung gian của cấp trước.
# - Kiểm tra candidate xuất hiện trong Transaction ID nào.
# - Đếm support cho từng candidate.
# - Tạo bản ghi trung gian cho cấp tiếp theo.
#
# Từ cấp 2 trở đi, hàm không cần đọc transaction gốc.
# ============================================================

function build_candidate_records(
    previous_candidate_records::Dict{Int, Vector{Itemset}},
    candidate_itemsets::Vector{Itemset}
)

    candidate_support_counts = MiningResult()

    current_candidate_records = Dict{Int, Vector{Itemset}}()

    # Khởi tạo support count bằng 0 cho mỗi candidate.
    for candidate_itemset in candidate_itemsets
        candidate_support_counts[candidate_itemset] = 0
    end

    # Duyệt các bản ghi trung gian của cấp trước.
    for (transaction_id, previous_itemsets) in previous_candidate_records

        # Chuyển thành Set để kiểm tra nhanh hơn.
        previous_itemset_lookup = Set{Itemset}(previous_itemsets)

        # Lưu các candidate xuất hiện trong transaction hiện tại.
        matching_candidates = Itemset[]

        for candidate_itemset in candidate_itemsets

            number_of_items = length(candidate_itemset)

            # Tạo tập sinh thứ nhất bằng cách bỏ item cuối.
            first_generator_items = Int[]

            for item_position in 1:(number_of_items - 1)
                push!(
                    first_generator_items,
                    candidate_itemset[item_position]
                )
            end

            first_generator = Tuple(first_generator_items)

            # Tạo tập sinh thứ hai bằng cách bỏ item áp cuối.
            second_generator_items = Int[]

            for item_position in 1:number_of_items

                if item_position != number_of_items - 1
                    push!(
                        second_generator_items,
                        candidate_itemset[item_position]
                    )
                end
            end

            second_generator = Tuple(second_generator_items)

            # Nếu transaction có cả hai tập sinh,
            # transaction đó cũng chứa candidate hiện tại.
            if first_generator in previous_itemset_lookup &&
               second_generator in previous_itemset_lookup

                push!(matching_candidates, candidate_itemset)

                candidate_support_counts[candidate_itemset] += 1
            end
        end

        # Chỉ giữ Transaction ID còn chứa candidate.
        if !isempty(matching_candidates)
            current_candidate_records[transaction_id] = matching_candidates
        end
    end

    return candidate_support_counts, current_candidate_records
end


# ============================================================
# HÀM 3: mine_apriori_tid
#
# Chức năng:
# - Tìm các frequent 1-itemsets.
# - Sinh candidate cấp tiếp theo.
# - Đếm support bằng dữ liệu trung gian.
# - Giữ những candidate đạt minimum support.
# - Lặp lại cho đến khi không còn candidate mới.
#
# Trả về toàn bộ frequent itemsets và support count.
# ============================================================

function mine_apriori_tid(
    transactions::Transactions,
    minimum_support_count::Int
)::MiningResult

    # Kiểm tra cơ sở dữ liệu đầu vào.
    validate_transactions(transactions)

    # Kiểm tra support count hợp lệ.
    if minimum_support_count < 1 ||
       minimum_support_count > length(transactions)

        throw(ArgumentError("Minimum support count is out of range."))
    end

    # Bước 1: Tìm các itemset phổ biến có một item.
    all_frequent_itemsets, previous_candidate_records = build_level_one(
        transactions,
        minimum_support_count
    )

    previous_frequent_itemsets = collect(keys(all_frequent_itemsets))

    # Bước 2: Lặp để tìm các itemset có kích thước lớn hơn.
    while !isempty(previous_frequent_itemsets)

        # Sinh candidate từ frequent itemsets cấp trước.
        candidate_itemsets = generate_candidates(
            previous_frequent_itemsets
        )

        if isempty(candidate_itemsets)
            break
        end

        # Đếm support bằng các bản ghi trung gian.
        candidate_support_counts, current_candidate_records =
            build_candidate_records(
                previous_candidate_records,
                candidate_itemsets
            )

        current_frequent_itemsets = Itemset[]

        # Lọc các candidate đạt minimum support.
        for (itemset, support_count) in candidate_support_counts

            if support_count >= minimum_support_count

                all_frequent_itemsets[itemset] = support_count

                push!(current_frequent_itemsets, itemset)
            end
        end

        # Cập nhật dữ liệu cho vòng khai thác tiếp theo.
        previous_candidate_records = current_candidate_records

        previous_frequent_itemsets = current_frequent_itemsets
    end

    return all_frequent_itemsets
end