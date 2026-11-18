# Đọc dữ liệu giao dịch từ file văn bản.
# Mỗi dòng là một giao dịch, các item cách nhau bằng khoảng trắng.
# Đọc các giao dịch từ file theo định dạng SPMF.
# Sử dụng open do để bảo đảm file được đóng khi có lỗi.
function read_transactions(file_path::AbstractString)::Transactions

    if !isfile(file_path)
        throw(ArgumentError("Input file does not exist: $(file_path)"))
    end

    transactions = Transactions()

    # Julia sẽ tự đóng file sau khi kết thúc khối do,
    # kể cả khi chương trình phát sinh exception.
    open(file_path, "r") do input_file

        for (line_number, line) in enumerate(eachline(input_file))

            current_line = strip(line)

            # Bỏ qua các dòng chú thích.
            if startswith(current_line, "#") ||
               startswith(current_line, "%") ||
               startswith(current_line, "@")
                continue
            end

            if isempty(current_line)
                throw(ArgumentError("Empty transaction at line $(line_number)."))
            end

            item_ids = Int[]

            # Chuyển mỗi mã item từ chuỗi thành số nguyên.
            for item_text in split(current_line)

                item_id = tryparse(Int, item_text)

                if item_id === nothing
                    throw(ArgumentError("Invalid item at line $(line_number): $(item_text)"))
                end

                push!(item_ids, item_id)
            end

            normalized_transaction = normalize_transaction(item_ids)

            push!(transactions, normalized_transaction)
        end
    end

    validate_transactions(transactions)

    return transactions
end


function write_transactions(file_path::AbstractString, transactions::Transactions)
    validate_transactions(transactions)
    mkpath(dirname(file_path))
    open(file_path, "w") do output_file
        for transaction in transactions
            println(output_file, join(transaction, ' '))
        end
    end
    return nothing
end

# Ghi kết quả frequent itemsets ra file theo định dạng SPMF.
# Ví dụ một dòng: 1 2 #SUP: 3
function write_itemsets(
    file_path::AbstractString,
    frequent_itemsets::MiningResult
)

    # Tạo thư mục chứa file kết quả nếu chưa tồn tại.
    mkpath(dirname(file_path))

    sorted_itemsets = sort(collect(keys(frequent_itemsets)))

    open(file_path, "w") do output_file

        for itemset in sorted_itemsets

            item_text = join(itemset, " ")

            support_count = frequent_itemsets[itemset]

            println(
                output_file,
                "$(item_text) #SUP: $(support_count)"
            )
        end
    end

    return nothing
end


# Đọc kết quả frequent itemsets từ file SPMF.
# Trả về Dict với khóa là itemset và giá trị là support count.
function read_itemsets(file_path::AbstractString)::MiningResult

    if !isfile(file_path)
        throw(ArgumentError("Result file does not exist: $(file_path)"))
    end

    frequent_itemsets = MiningResult()

    for (line_number, line) in enumerate(eachline(file_path))

        current_line = strip(line)

        # File kết quả rỗng là trường hợp hợp lệ.
        if isempty(current_line)
            continue
        end

        # Tách itemset và support tại chuỗi #SUP:.
        line_parts = split(current_line, "#SUP:")

        if length(line_parts) != 2
            throw(ArgumentError("Invalid itemset result at line $(line_number)."))
        end

        item_ids = Int[]

        # Đọc danh sách item của itemset.
        for item_text in split(strip(line_parts[1]))

            item_id = tryparse(Int, item_text)

            if item_id === nothing
                throw(ArgumentError("Invalid itemset at line $(line_number)."))
            end

            push!(item_ids, item_id)
        end

        itemset = Tuple(normalize_transaction(item_ids))

        # Đọc support count.
        support_count = tryparse(Int, strip(line_parts[2]))

        if support_count === nothing || support_count <= 0
            throw(ArgumentError("Invalid support at line $(line_number)."))
        end

        if haskey(frequent_itemsets, itemset)
            throw(ArgumentError("Duplicate itemset at line $(line_number)."))
        end

        frequent_itemsets[itemset] = support_count
    end

    return frequent_itemsets
end
