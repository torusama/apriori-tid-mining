# Chạy thuật toán Apriori_TID của SPMF bằng Java.
# SPMF chỉ được dùng để đối chiếu, không thay thế code nhóm.
# Chạy thuật toán Apriori-TID của SPMF bằng Java.
# Sao chép file dữ liệu sang thư mục tạm để tránh lỗi
# Java không đọc đúng đường dẫn chứa ký tự tiếng Việt.
function run_spmf(
    spmf_jar_path::AbstractString,
    input_path::AbstractString,
    output_path::AbstractString,
    minimum_support::Real;
    output_stream::IO = stdout
)::MiningResult

    # Kiểm tra file JAR của SPMF.
    if !isfile(spmf_jar_path)
        throw(ArgumentError("SPMF JAR file does not exist: $(spmf_jar_path)"))
    end

    # Kiểm tra file dữ liệu.
    if !isfile(input_path)
        throw(ArgumentError("Input file does not exist: $(input_path)"))
    end

    # Kiểm tra Java đã được cài đặt.
    if Sys.which("java") === nothing
        throw(ArgumentError("Java is not available on PATH."))
    end

    # Kiểm tra minimum support.
    calculate_minimum_support_count(minimum_support, 1)

    # Chuyển 0.4 thành "40.0%" để SPMF sử dụng.
    minimum_support_percentage = string(
        round(minimum_support * 100; digits = 10),
        "%"
    )

    # Tạo thư mục chứa kết quả nếu chưa tồn tại.
    mkpath(dirname(output_path))

    # Tạo thư mục tạm trong Windows.
    # Trên máy hiện tại, Julia đang dùng đường dẫn Temp dạng ASCII.
    return mktempdir() do temporary_directory

        # Tạo đường dẫn file dữ liệu tạm.
        temporary_input_path = joinpath(
            temporary_directory,
            "spmf_input.txt"
        )

        # Sao chép dữ liệu sang thư mục tạm.
        # Dữ liệu gốc của project không bị thay đổi.
        cp(
            input_path,
            temporary_input_path;
            force = true
        )

        # Chạy SPMF với file đầu vào trong thư mục tạm.
        command = `java -jar $spmf_jar_path run Apriori_TID $temporary_input_path $output_path $minimum_support_percentage`

        run(pipeline(command; stdout = output_stream))

        # Kiểm tra SPMF có tạo file kết quả hay không.
        if !isfile(output_path)
            error("SPMF did not create an output file.")
        end

        # Đọc kết quả từ file SPMF.
        spmf_results = read_itemsets(output_path)

        return spmf_results
    end
end

# So sánh kết quả của nhóm với kết quả tham chiếu.
#
# missing_itemsets: SPMF có nhưng code nhóm không có.
# extra_itemsets: code nhóm có nhưng SPMF không có.
# wrong_support: cùng itemset nhưng support khác nhau.
function compare_results(
    actual_results::MiningResult,
    expected_results::MiningResult
)

    actual_itemsets = Set(keys(actual_results))
    expected_itemsets = Set(keys(expected_results))

    missing_itemsets = sort(
        collect(setdiff(expected_itemsets, actual_itemsets))
    )

    extra_itemsets = sort(
        collect(setdiff(actual_itemsets, expected_itemsets))
    )

    wrong_support = Dict{Itemset, Tuple{Int, Int}}()

    matching_itemsets = 0

    # So support cho từng itemset trong kết quả tham chiếu.
    for itemset in expected_itemsets

        if haskey(actual_results, itemset)

            actual_support = actual_results[itemset]
            expected_support = expected_results[itemset]

            if actual_support == expected_support

                matching_itemsets += 1

            else

                wrong_support[itemset] = (
                    actual_support,
                    expected_support
                )
            end
        end
    end

    total_expected_itemsets = length(expected_results)

    # Tính tỷ lệ itemset khớp support.
    if total_expected_itemsets == 0

        matching_percentage = isempty(actual_results) ? 100.0 : 0.0

    else

        matching_percentage = (
            matching_itemsets / total_expected_itemsets
        ) * 100
    end

    # Kết quả chỉ khớp hoàn toàn nếu không thiếu, thừa hay sai support.
    matches = isempty(missing_itemsets) &&
              isempty(extra_itemsets) &&
              isempty(wrong_support)

    return (
        matches = matches,
        matching_itemsets = matching_itemsets,
        matching_percentage = matching_percentage,
        missing_itemsets = missing_itemsets,
        extra_itemsets = extra_itemsets,
        wrong_support = wrong_support
    )
end


# In thông tin đối chiếu giữa code nhóm và SPMF.
function print_comparison(comparison)

    println("Exact match: ", comparison.matches)
    println("Matching itemsets: ", comparison.matching_itemsets)
    println(
        "Match rate: ",
        round(comparison.matching_percentage; digits = 2),
        "%"
    )

    println("Missing itemsets: ", comparison.missing_itemsets)
    println("Extra itemsets: ", comparison.extra_itemsets)
    println("Wrong support counts: ", comparison.wrong_support)

    return nothing
end
