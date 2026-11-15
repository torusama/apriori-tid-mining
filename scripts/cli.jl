using FrequentItemsetMining


# Đọc các tham số được nhập từ terminal.
#
# Ví dụ:
# --input data/toy/sample.txt
# --output result/output.txt
# --minsup 0.6
# --implementation basic
function parse_arguments(arguments::Vector{String})

    # Các tham số được nhập theo từng cặp tên và giá trị.
    if length(arguments) % 2 != 0
        throw(ArgumentError("Every option must have a value."))
    end

    options = Dict{String, String}()

    for argument_index in 1:2:length(arguments)

        option_name = arguments[argument_index]
        option_value = arguments[argument_index + 1]

        # Chỉ chấp nhận những tham số mà chương trình hỗ trợ.
        if !(option_name in (
            "--input",
            "--output",
            "--minsup",
            "--implementation"
        ))
            throw(ArgumentError("Unknown option: $(option_name)"))
        end

        options[option_name] = option_value
    end

    # Kiểm tra các tham số bắt buộc.
    required_options = ["--input", "--output", "--minsup"]

    for required_option in required_options

        if !haskey(options, required_option)
            throw(ArgumentError("Missing required option: $(required_option)"))
        end
    end

    return options
end


# Hàm chính dùng để chạy thuật toán từ terminal.
function main(arguments::Vector{String} = ARGS)

    options = parse_arguments(arguments)

    input_path = options["--input"]
    output_path = options["--output"]

    minimum_support = tryparse(
        Float64,
        options["--minsup"]
    )

    if minimum_support === nothing
        throw(ArgumentError("Minimum support must be a number."))
    end

    implementation_name = get(
        options,
        "--implementation",
        "basic"
    )

    if !(implementation_name in ("basic", "optimized"))
        throw(ArgumentError("Implementation must be basic or optimized."))
    end

    # Đọc dữ liệu giao dịch.
    transactions = read_transactions(input_path)

    # Chạy thuật toán Apriori-TID.
    frequent_itemsets = mine(
        transactions;
        minimum_support = minimum_support,
        implementation = Symbol(implementation_name)
    )

    # Ghi kết quả ra file.
    write_itemsets(output_path, frequent_itemsets)

    # In thông tin sau khi chạy.
    println("Input transactions: ", length(transactions))
    println("Frequent itemsets: ", length(frequent_itemsets))
    println("Output file: ", output_path)

    return frequent_itemsets
end


# Chỉ tự chạy main khi file được gọi trực tiếp.
# Nếu file được include trong bài test thì không tự chạy.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end