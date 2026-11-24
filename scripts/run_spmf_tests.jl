using FrequentItemsetMining


# Chạy so sánh Apriori-TID với SPMF trên nhiều cơ sở dữ liệu.
# Kết quả được lưu tại result/correctness/spmf_comparison.txt.
function main(arguments::Vector{String} = ARGS)

    if length(arguments) != 1
        throw(ArgumentError("Usage: run_spmf_tests.jl SPMF_JAR"))
    end

    spmf_jar_path = arguments[1]

    # Xác định các thư mục theo đường dẫn project.
    project_directory = normpath(joinpath(@__DIR__, ".."))

    fixture_directory = joinpath(
        project_directory,
        "tests",
        "fixtures"
    )

    report_directory = joinpath(
        project_directory,
        "result",
        "correctness"
    )

    # Mỗi trường hợp gồm tên file và minimum support.
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

    report_lines = String[]

    all_cases_passed = true

    for (file_name, minimum_support) in test_cases

        # Đọc giao dịch của bộ test hiện tại.
        transaction_file = joinpath(
            fixture_directory,
            file_name
        )

        transactions = read_transactions(transaction_file)

        # Chạy thuật toán nhóm tự viết.
        actual_results = mine(
            transactions;
            minimum_support = minimum_support
        )

        # Tạo file tạm để nhận kết quả SPMF.
        spmf_output_file = tempname() * ".txt"

        try
            expected_results = run_spmf(
                spmf_jar_path,
                transaction_file,
                spmf_output_file,
                minimum_support
            )

            comparison = compare_results(
                actual_results,
                expected_results
            )

            # Ghi nhận kết quả của trường hợp hiện tại.
            all_cases_passed = all_cases_passed && comparison.matches

            summary_line = (
                "$(file_name) | " *
                "minimum_support=$(minimum_support) | " *
                "exact_match=$(comparison.matches)"
            )

            println(summary_line)
            push!(report_lines, summary_line)

            # Nếu sai thì lưu chi tiết các itemset có vấn đề.
            if !comparison.matches

                detail_line = (
                    "missing=$(comparison.missing_itemsets), " *
                    "extra=$(comparison.extra_itemsets), " *
                    "wrong_support=$(comparison.wrong_support)"
                )

                println(detail_line)
                push!(report_lines, detail_line)
            end

        finally
            # Xóa file tạm của SPMF.
            if isfile(spmf_output_file)
                rm(spmf_output_file)
            end
        end
    end

    # Tạo thư mục báo cáo và ghi kết quả.
    mkpath(report_directory)

    report_path = joinpath(
        report_directory,
        "spmf_comparison.txt"
    )

    write(report_path, join(report_lines, "\n") * "\n")

    println("Comparison report: ", report_path)

    if !all_cases_passed
        error("Some results do not match SPMF.")
    end

    println("All SPMF comparisons passed.")

    return nothing
end


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
