using FrequentItemsetMining

# So sánh kết quả Apriori-TID của nhóm và SPMF trên một file.
#
# Tham số dòng lệnh:
# 1. Đường dẫn file spmf.jar.
# 2. Đường dẫn file giao dịch.
# 3. Minimum support.
function main(arguments::Vector{String} = ARGS)

    if length(arguments) != 3
        throw(ArgumentError(
            "Usage: compare_spmf.jl SPMF_JAR INPUT_FILE MINIMUM_SUPPORT"
        ))
    end

    spmf_jar_path = arguments[1]
    input_path = arguments[2]

    minimum_support = tryparse(Float64, arguments[3])

    if minimum_support === nothing
        throw(ArgumentError("Minimum support must be a number."))
    end

    # Chạy thuật toán do nhóm tự cài đặt.
    transactions = read_transactions(input_path)

    actual_results = mine(
        transactions;
        minimum_support = minimum_support
    )

    # Tạo file tạm để lưu kết quả của SPMF.
    temporary_output_path = tempname() * ".txt"

    try
        # Chạy SPMF trên cùng file và cùng minimum support.
        expected_results = run_spmf(
            spmf_jar_path,
            input_path,
            temporary_output_path,
            minimum_support
        )

        # So sánh kết quả của hai thuật toán.
        comparison = compare_results(
            actual_results,
            expected_results
        )

        print_comparison(comparison)

        if !comparison.matches
            error("Apriori-TID results do not match SPMF.")
        end

    finally
        # Xóa file tạm sau khi đối chiếu.
        if isfile(temporary_output_path)
            rm(temporary_output_path)
        end
    end

    return nothing
end


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end