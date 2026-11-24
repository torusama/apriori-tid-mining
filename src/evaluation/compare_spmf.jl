# Chỉ dùng SPMF làm tham chiếu; Java chạy với đường dẫn tương đối trong thư mục tạm.
function run_spmf(
    spmf_jar_path::AbstractString,
    input_path::AbstractString,
    output_path::AbstractString,
    minimum_support::Real;
    output_stream::IO = stdout
)::MiningResult
    if !isfile(spmf_jar_path)
        throw(ArgumentError("SPMF JAR file does not exist: $spmf_jar_path"))
    end
    if Sys.which("java") === nothing
        throw(ArgumentError("Java is not available on PATH."))
    end

    transactions = read_transactions(input_path)
    number_of_transactions = length(transactions)
    minimum_count = calculate_minimum_support_count(minimum_support, number_of_transactions)

    # SPMF làm tròn ngưỡng tương đối lên. Chọn một giá trị nằm trong khoảng
    # có cùng support count, tránh sai số ở ranh giới số thực.
    reference_percentage = string(100 * ((minimum_count - 0.5) / number_of_transactions), "%")
    mkpath(dirname(output_path))

    temporary_root = get(ENV, "SPMF_TEMP_DIR", tempdir())
    mkpath(temporary_root)
    return mktempdir(temporary_root) do temporary_directory
        temporary_jar = joinpath(temporary_directory, "spmf.jar")
        temporary_input = joinpath(temporary_directory, "input.txt")
        temporary_output = joinpath(temporary_directory, "output.txt")
        cp(spmf_jar_path, temporary_jar; force = true)
        write_transactions(temporary_input, transactions)

        command = Cmd(`java -jar spmf.jar run Apriori_TID input.txt output.txt $reference_percentage`;
                      dir = temporary_directory)
        run(pipeline(command; stdout = output_stream))
        if !isfile(temporary_output)
            error("SPMF did not create an output file.")
        end

        results = read_itemsets(temporary_output)
        cp(temporary_output, output_path; force = true)
        return results
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
