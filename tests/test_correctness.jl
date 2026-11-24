# Kiểm tra frequent itemsets và support count trên 5 database.
@testset "TASK 02 - Five toy databases" begin

    fixture_directory = joinpath(@__DIR__, "fixtures")

    # --------------------------------------------------------
    # Database 1: Dữ liệu giao dịch cơ bản.
    # --------------------------------------------------------

    basic_transactions = read_transactions(
        joinpath(fixture_directory, "toy_basic.txt")
    )

    expected_basic_results = MiningResult(
        (1,) => 4,
        (2,) => 4,
        (3,) => 4,
        (1, 2) => 3,
        (1, 3) => 3,
        (2, 3) => 3
    )

    actual_basic_results = mine(
        basic_transactions;
        minimum_support = 0.6
    )

    @test actual_basic_results == expected_basic_results


    # --------------------------------------------------------
    # Database 2: Nhiều giao dịch có nội dung giống nhau.
    # --------------------------------------------------------

    identical_transactions = read_transactions(
        joinpath(fixture_directory, "toy_identical.txt")
    )

    expected_identical_results = MiningResult(
        (1,) => 4,
        (2,) => 4,
        (1, 2) => 4
    )

    @test mine(
        identical_transactions;
        minimum_support = 1.0
    ) == expected_identical_results


    # --------------------------------------------------------
    # Database 3: Dữ liệu thưa, ít item xuất hiện cùng nhau.
    # --------------------------------------------------------

    sparse_transactions = read_transactions(
        joinpath(fixture_directory, "toy_sparse.txt")
    )

    @test mine(
        sparse_transactions;
        minimum_support = 0.4
    ) == MiningResult((1,) => 2)

    # Với support 100% không có itemset nào phổ biến.
    @test isempty(
        mine(sparse_transactions; minimum_support = 1.0)
    )


    # --------------------------------------------------------
    # Database 4: Dữ liệu dày, có frequent itemsets cấp 3.
    # --------------------------------------------------------

    dense_transactions = read_transactions(
        joinpath(fixture_directory, "toy_dense.txt")
    )

    expected_dense_results = MiningResult(
        (1,) => 5,
        (2,) => 4,
        (3,) => 4,
        (4,) => 4,
        (1, 2) => 4,
        (1, 3) => 4,
        (1, 4) => 4,
        (2, 3) => 3,
        (2, 4) => 3,
        (3, 4) => 3,
        (1, 2, 3) => 3,
        (1, 2, 4) => 3,
        (1, 3, 4) => 3
    )

    @test mine(
        dense_transactions;
        minimum_support = 0.6
    ) == expected_dense_results


    # --------------------------------------------------------
    # Database 5: Kiểm tra support bằng đúng ngưỡng.
    # --------------------------------------------------------

    boundary_transactions = read_transactions(
        joinpath(fixture_directory, "toy_boundary.txt")
    )

    expected_boundary_results = MiningResult(
        (1,) => 3,
        (2,) => 4,
        (1, 2) => 2
    )

    @test mine(
        boundary_transactions;
        minimum_support = 0.4
    ) == expected_boundary_results

    @test mine(
        boundary_transactions;
        minimum_support = 0.6
    ) == MiningResult(
        (1,) => 3,
        (2,) => 4
    )
end


# Kiểm tra ví dụ trong Figure 3 của paper VLDB 1994.
@testset "TASK 02 - VLDB 1994 Figure 3" begin

    transactions = Transactions([
        [1, 3, 4],
        [2, 3, 5],
        [1, 2, 3, 5],
        [2, 5]
    ])

    expected_results = MiningResult(
        (1,) => 2,
        (2,) => 3,
        (3,) => 3,
        (5,) => 3,
        (1, 3) => 2,
        (2, 3) => 2,
        (2, 5) => 3,
        (3, 5) => 2,
        (2, 3, 5) => 2
    )

    actual_results = mine(
        transactions;
        minimum_support = 0.5
    )

    @test actual_results == expected_results
end


# Kiểm tra trường hợp đặc biệt của thuật toán.
@testset "TASK 02 - Boundary cases" begin

    # Support 100% nhưng không item nào có trong tất cả giao dịch.
    @test mine(
        Transactions([[7], [7], [8]]);
        minimum_support = 1.0
    ) == MiningResult()

    # Item 7 xuất hiện hai trong ba giao dịch.
    @test mine(
        Transactions([[7], [7], [8]]);
        minimum_support = 0.5
    ) == MiningResult(
        (7,) => 2
    )

    # Một transaction chứa ba item tạo ra 7 tập khác rỗng.
    @test mine(
        Transactions([[1, 2, 3]]);
        minimum_support = 1.0
    ) == MiningResult(
        (1,) => 1,
        (2,) => 1,
        (3,) => 1,
        (1, 2) => 1,
        (1, 3) => 1,
        (2, 3) => 1,
        (1, 2, 3) => 1
    )
end
# So sánh hai bản trên mọi fixture ở nhiều ngưỡng, kể cả ngưỡng bằng đúng support.
@testset "TASK 03 - Optimized Apriori-TID" begin
    for fixture in readdir(joinpath(@__DIR__, "fixtures"); join = true)
        transactions = read_transactions(fixture)
        for minimum_support in (0.2, 0.4, 0.5, 0.6, 1.0)
            @test mine(transactions; minimum_support, implementation = :optimized) ==
                  mine(transactions; minimum_support, implementation = :basic)
        end
    end
end


# Đếm trực tiếp trên dữ liệu nhỏ để kiểm tra độc lập với hai bản Apriori-TID.
@testset "Independent support counts" begin
    transactions = [[1, 2, 3], [1, 3, 4], [2, 3], [1, 2, 4], [4]]
    expected = MiningResult()
    subsets = Itemset[(1,), (2,), (3,), (4,),
        (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4),
        (1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4), (1, 2, 3, 4)]
    for items in subsets
        support_count = 0
        for transaction in transactions
            if all(item -> item in transaction, items)
                support_count += 1
            end
        end
        if support_count >= 2
            expected[items] = support_count
        end
    end
    for implementation in (:basic, :optimized)
        @test mine(transactions; minimum_support = 0.4, implementation) == expected
        @test_throws ArgumentError mine([[2, 1]]; minimum_support = 0.4, implementation)
    end
    @test_throws ArgumentError FrequentItemsetMining.mine_apriori_tid_optimized([[1]], 0)
    @test_throws ArgumentError FrequentItemsetMining.mine_apriori_tid_optimized([[1]], 2)
end
