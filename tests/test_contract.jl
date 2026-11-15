# Kiểm tra các hàm xử lý dữ liệu cơ bản.
@testset "TASK 00 - Base functions" begin

    # Chuẩn hóa một giao dịch.
    @test normalize_transaction([3, 1, 2, 2]) == [1, 2, 3]

    @test normalize_transaction([4]) == [4]

    # Hai giao dịch giống nhau vẫn được giữ lại.
    @test normalize_transactions(
        [[2, 1], [1, 2]]
    ) == [[1, 2], [1, 2]]

    # Kiểm tra chuyển minimum support sang support count.
    @test calculate_minimum_support_count(0.4, 5) == 2

    @test calculate_minimum_support_count(0.41, 5) == 3

    @test calculate_minimum_support_count(1.0, 5) == 5

    # Kiểm tra giao dịch rỗng.
    @test_throws ArgumentError normalize_transaction(Int[])

    # Kiểm tra mã item không hợp lệ.
    @test_throws ArgumentError normalize_transaction([1, 0, 2])

    # Kiểm tra cơ sở dữ liệu rỗng.
    @test_throws ArgumentError validate_transactions(Transactions())

    # Kiểm tra giao dịch chưa sắp xếp.
    @test_throws ArgumentError validate_transactions([[2, 1]])

    # Kiểm tra giao dịch có item trùng.
    @test_throws ArgumentError validate_transactions([[1, 1]])

    # Kiểm tra minimum support không hợp lệ.
    @test_throws ArgumentError calculate_minimum_support_count(0.0, 5)

    @test_throws ArgumentError calculate_minimum_support_count(1.2, 5)

    @test_throws ArgumentError calculate_minimum_support_count(NaN, 5)

    @test_throws ArgumentError calculate_minimum_support_count(0.4, 0)

    # Dữ liệu hợp lệ không phát sinh lỗi.
    @test validate_transactions([[1, 2], [1, 2]]) === nothing

    # Bản Basic phải trả về frequent itemsets thật.
    expected_results = MiningResult(
        (1,) => 1,
        (2,) => 1,
        (1, 2) => 1
    )

    @test mine(
        [[1, 2]];
        minimum_support = 1.0
    ) == expected_results

    # Kiểm tra người dùng chọn sai thuật toán.
    @test_throws ArgumentError mine(
        [[1, 2]];
        implementation = :unknown
    )

    # TASK 03 chưa viết phiên bản optimized.
    @test_throws ErrorException mine(
        [[1, 2]];
        implementation = :optimized
    )
end