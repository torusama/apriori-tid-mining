using FrequentItemsetMining


# Đọc các tham số được nhập từ terminal.
#
# Ví dụ:
# --input data/toy/sample.txt
# --output result/output.txt
# --minsup 0.6
# --implementation basic
function parse_arguments(arguments::Vector{String})

    options = Dict{String, String}()
    argument_index = 1
    supported_options = ("--input", "--output", "--minsup", "--implementation")

    while argument_index <= length(arguments)
        argument = arguments[argument_index]
        if startswith(argument, "--")
            argument in supported_options || throw(ArgumentError("Unknown option: $argument"))
            argument_index < length(arguments) || throw(ArgumentError("Missing value for $argument"))
            value = arguments[argument_index + 1]
            startswith(value, "--") && throw(ArgumentError("Missing value for $argument"))
            haskey(options, argument) && throw(ArgumentError("Duplicate option: $argument"))
            options[argument] = value
            argument_index += 2
        else
            # Hỗ trợ đường dẫn input trực tiếp như ví dụ trong đề.
            haskey(options, "--input") && throw(ArgumentError("Only one input file is allowed."))
            options["--input"] = argument
            argument_index += 1
        end
    end

    for required_option in ("--input", "--minsup")
        haskey(options, required_option) || throw(ArgumentError("Missing required option: $required_option"))
    end
    get!(options, "--output", "result/output.txt")

    return options
end


# Hàm chính dùng để chạy thuật toán từ terminal.
function main(arguments::Vector{String} = ARGS)

    if arguments == ["--help"] || arguments == ["-h"]
        println("Usage: julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt [--output result/output.txt] [--implementation basic|optimized]")
        println("The --input FILE form is also supported. Default output: result/output.txt.")
        return nothing
    end

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
