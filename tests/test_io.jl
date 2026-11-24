# Kiểm tra các hàm đọc và ghi dữ liệu SPMF.
@testset "TASK 02 - SPMF file input and output" begin

    # Tạo thư mục tạm để không ảnh hưởng dữ liệu project.
    mktempdir() do temporary_directory

        transaction_file = joinpath(
            temporary_directory,
            "transactions.txt"
        )

        # Tạo file giao dịch thử nghiệm.
        write(
            transaction_file,
            "1 2 3\n1 2\n2 3\n"
        )

        expected_transactions = Transactions([
            [1, 2, 3],
            [1, 2],
            [2, 3]
        ])

        @test read_transactions(transaction_file) == expected_transactions

        # Kiểm tra ghi rồi đọc lại kết quả khai thác.
        result_file = joinpath(
            temporary_directory,
            "output.txt"
        )

        expected_itemsets = MiningResult(
            (1,) => 2,
            (2,) => 3,
            (1, 2) => 2
        )

        write_itemsets(result_file, expected_itemsets)

        @test read_itemsets(result_file) == expected_itemsets

        # Kiểm tra định dạng support của SPMF.
        file_content = read(result_file, String)

        @test occursin("1 2 #SUP: 2", file_content)

        # Kiểm tra trường hợp không có frequent itemset.
        empty_result_file = joinpath(
            temporary_directory,
            "empty.txt"
        )

        write_itemsets(empty_result_file, MiningResult())

        @test read(empty_result_file, String) == ""

        @test isempty(read_itemsets(empty_result_file))

        # Kiểm tra bỏ qua dòng chú thích trong dữ liệu SPMF.
        commented_file = joinpath(
            temporary_directory,
            "commented.txt"
        )

        write(
            commented_file,
            "# comment\n% comment\n@ comment\n1 2\n"
        )

        @test read_transactions(commented_file) == Transactions([
            [1, 2]
        ])

        # Kiểm tra giao dịch rỗng.
        invalid_file = joinpath(
            temporary_directory,
            "invalid.txt"
        )

        write(invalid_file, "1 2\n\n2 3\n")

        @test_throws ArgumentError read_transactions(invalid_file)

        # Kiểm tra item không phải số nguyên.
        write(invalid_file, "1 bad 3\n")

        @test_throws ArgumentError read_transactions(invalid_file)

        # Kiểm tra mã item bằng 0.
        write(invalid_file, "1 0 3\n")

        @test_throws ArgumentError read_transactions(invalid_file)

        # Kiểm tra support không hợp lệ.
        invalid_result_file = joinpath(
            temporary_directory,
            "invalid_result.txt"
        )

        write(invalid_result_file, "1 2 #SUP: wrong\n")

        @test_throws ArgumentError read_itemsets(invalid_result_file)

        # Kiểm tra đường dẫn file không tồn tại.
        missing_file = joinpath(
            temporary_directory,
            "missing.txt"
        )

        @test_throws ArgumentError read_transactions(missing_file)
    end
end


# Kiểm tra chương trình CLI với dữ liệu thử nghiệm.
@testset "TASK 02 - Command line interface" begin

    # Nạp file CLI để có thể gọi trực tiếp hàm main().
    include(joinpath(@__DIR__, "..", "scripts", "cli.jl"))

    mktempdir() do temporary_directory

        input_path = joinpath(
            @__DIR__,
            "fixtures",
            "toy_basic.txt"
        )

        output_path = joinpath(
            temporary_directory,
            "cli_results.txt"
        )

        # Chạy thuật toán bằng các tham số CLI.
        actual_results = main([
            "--input", input_path,
            "--output", output_path,
            "--minsup", "0.6",
            "--implementation", "basic"
        ])

        # Kiểm tra file kết quả đã được tạo.
        @test isfile(output_path)

        # Kết quả đọc từ file phải trùng kết quả chương trình.
        @test read_itemsets(output_path) == actual_results

        @test actual_results[(1, 2)] == 3

        @test main([
            "--input", input_path,
            "--output", output_path,
            "--minsup", "0.6",
            "--implementation", "optimized"
        ]) == actual_results
        @test read_itemsets(output_path) == actual_results

        # Kiểm tra cú pháp đường dẫn input theo ví dụ của đề.
        @test main(["--minsup", "0.6", input_path, "--output", output_path,
                    "--implementation", "optimized"]) == actual_results
        @test read_itemsets(output_path) == actual_results
        @test parse_arguments(["--minsup", "0.6", input_path])["--output"] == "result/output.txt"
        @test_throws ArgumentError parse_arguments(["--minsup", "0.6", input_path, "--input", input_path])
        @test_throws ArgumentError parse_arguments(["--minsup", "--input", input_path])

        # Thiếu tham số bắt buộc phải báo lỗi.
        @test_throws ArgumentError main([
            "--input", input_path
        ])

        # Minimum support sai định dạng phải báo lỗi.
        @test_throws ArgumentError main([
            "--input", input_path,
            "--output", output_path,
            "--minsup", "wrong"
        ])
    end
end
