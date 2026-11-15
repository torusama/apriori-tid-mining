# Kiểm tra quá trình sinh các candidate itemsets.
@testset "TASK 01 - Candidate generation" begin

    # Từ các item đơn tạo candidate có hai item.
    single_itemsets = Itemset[
        (1,),
        (2,),
        (3,)
    ]

    expected_candidates = Itemset[
        (1, 2),
        (1, 3),
        (2, 3)
    ]

    @test generate_candidates(single_itemsets) == expected_candidates

    # Từ các cặp phổ biến sinh candidate có ba item.
    previous_itemsets = Itemset[
        (1, 2),
        (1, 3),
        (2, 3)
    ]

    @test generate_candidates(previous_itemsets) == Itemset[
        (1, 2, 3)
    ]

    # Nếu thiếu tập con (2, 3) thì không tạo (1, 2, 3).
    incomplete_itemsets = Itemset[
        (1, 2),
        (1, 3)
    ]

    @test isempty(generate_candidates(incomplete_itemsets))

    # Kiểm tra hàm phát hiện tập con không phổ biến.
    incomplete_lookup = Set{Itemset}([
        (1, 2),
        (1, 3)
    ])

    @test has_infrequent_subset(
        (1, 2, 3),
        incomplete_lookup
    )

    complete_lookup = Set{Itemset}([
        (1, 2),
        (1, 3),
        (2, 3)
    ])

    @test !has_infrequent_subset(
        (1, 2, 3),
        complete_lookup
    )

    # Danh sách đầu vào rỗng không sinh ra candidate.
    @test isempty(generate_candidates(Itemset[]))
end


# Kiểm tra cách Apriori-TID tạo và sử dụng bản ghi trung gian.
@testset "TASK 01 - Intermediate transaction records" begin

    transactions = Transactions([
        [1, 2, 3],
        [1, 2],
        [2, 3]
    ])

    # Tìm frequent 1-itemsets và dữ liệu trung gian cấp 1.
    frequent_single_itemsets, previous_records = build_level_one(
        transactions,
        2
    )

    expected_single_itemsets = MiningResult(
        (1,) => 2,
        (2,) => 3,
        (3,) => 2
    )

    @test frequent_single_itemsets == expected_single_itemsets

    @test previous_records[1] == Itemset[
        (1,),
        (2,),
        (3,)
    ]

    @test previous_records[2] == Itemset[
        (1,),
        (2,)
    ]

    # Sinh candidate có hai item.
    candidate_itemsets = Itemset[
        (1, 2),
        (1, 3),
        (2, 3)
    ]

    # Đếm support và tạo dữ liệu trung gian cấp 2.
    candidate_support_counts, current_records = build_candidate_records(
        previous_records,
        candidate_itemsets
    )

    expected_support_counts = MiningResult(
        (1, 2) => 2,
        (1, 3) => 1,
        (2, 3) => 2
    )

    @test candidate_support_counts == expected_support_counts

    @test Set(current_records[1]) == Set(candidate_itemsets)

    @test current_records[2] == Itemset[
        (1, 2)
    ]

    @test current_records[3] == Itemset[
        (2, 3)
    ]

    # Kiểm tra candidate có ba item bằng dữ liệu cấp 2.
    next_candidates = Itemset[
        (1, 2, 3)
    ]

    next_support_counts, next_records = build_candidate_records(
        current_records,
        next_candidates
    )

    @test next_support_counts[(1, 2, 3)] == 1

    # Chỉ transaction đầu tiên chứa cả ba item.
    @test length(next_records) == 1
end