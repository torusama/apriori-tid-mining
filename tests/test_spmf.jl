# Kiểm tra bộ so sánh kết quả SPMF.
@testset "TASK 02 - SPMF comparator" begin

    expected_results = MiningResult(
        (1,) => 3,
        (2,) => 2,
        (1, 2) => 2
    )

    actual_results = MiningResult(
        (1,) => 3,
        (2,) => 1,
        (3,) => 1
    )

    comparison = compare_results(
        actual_results,
        expected_results
    )

    # Hai kết quả này phải khác nhau.
    @test !comparison.matches

    # Code nhóm thiếu itemset (1, 2).
    @test comparison.missing_itemsets == Itemset[
        (1, 2)
    ]

    # Code nhóm có thêm itemset (3,).
    @test comparison.extra_itemsets == Itemset[
        (3,)
    ]

    # Itemset (2,) có support sai.
    @test comparison.wrong_support[(2,)] == (1, 2)

    # Hai kết quả giống nhau phải khớp hoàn toàn.
    @test compare_results(
        expected_results,
        expected_results
    ).matches

    # Hai kết quả rỗng cũng phải khớp.
    @test compare_results(
        MiningResult(),
        MiningResult()
    ).matches
end


# Kiểm tra trực tiếp với SPMF nếu đã cấu hình file JAR.
@testset "TASK 02 - SPMF integration" begin

    spmf_jar_path = get(ENV, "SPMF_JAR", "")

    # Nếu đường dẫn là tương đối thì tính từ thư mục project.
    if !isempty(spmf_jar_path) && !isabspath(spmf_jar_path)

        spmf_jar_path = normpath(
            joinpath(@__DIR__, "..", spmf_jar_path)
        )
    end

    # Chỉ chạy SPMF khi có file JAR và Java.
    if isfile(spmf_jar_path) && Sys.which("java") !== nothing

        fixture_directory = joinpath(
            @__DIR__,
            "fixtures"
        )

        test_cases = [
            ("toy_basic.txt", 0.4),
            ("toy_basic.txt", 0.6),
            ("toy_identical.txt", 1.0),
            ("toy_sparse.txt", 0.4),
            ("toy_sparse.txt", 1.0),
            ("toy_dense.txt", 0.6),
            ("toy_boundary.txt", 0.4),
            ("toy_boundary.txt", 0.6),
            ("paper_figure3.txt", 0.5)
        ]

        for (file_name, minimum_support) in test_cases

            input_path = joinpath(
                fixture_directory,
                file_name
            )

            transactions = read_transactions(input_path)

            # Kết quả thuật toán nhóm tự cài đặt.
            actual_results = mine(
                transactions;
                minimum_support = minimum_support
            )

            # File tạm để lưu kết quả SPMF.
            output_path = tempname() * ".txt"

            try
                expected_results = run_spmf(
                    spmf_jar_path,
                    input_path,
                    output_path,
                    minimum_support
                )

                comparison = compare_results(
                    actual_results,
                    expected_results
                )

                @test comparison.matches
                optimized_results = mine(transactions; minimum_support, implementation = :optimized)
                @test compare_results(optimized_results, expected_results).matches

            finally
                if isfile(output_path)
                    rm(output_path)
                end
            end
        end

    else

        # Không ghi nhận là đã chạy SPMF khi chưa có môi trường.
        @info "SPMF integration tests skipped: set SPMF_JAR and install Java."
    end
end
