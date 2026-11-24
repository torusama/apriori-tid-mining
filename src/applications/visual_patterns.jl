# Đọc mỗi dòng thành một giao dịch và giữ dòng rỗng cho ảnh không có đặc trưng.
function read_visual_transactions(file_path::AbstractString)
    transactions = Transactions()
    open(file_path, "r") do input_file
        for line in eachline(input_file)
            if isempty(strip(line))
                push!(transactions, Int[])
            else
                items = Int[]
                for item_text in split(line)
                    push!(items, parse(Int, item_text))
                end
                push!(transactions, normalize_transaction(items))
            end
        end
    end
    if isempty(transactions)
        throw(ArgumentError("No image transactions found."))
    end
    return transactions
end

# Khai thác giao dịch có dữ liệu với ngưỡng support tính trên toàn bộ ảnh.
function mine_visual_transactions(transactions::Transactions, minimum_support::Real;
                                  implementation::Symbol = :basic)
    minimum_count = calculate_minimum_support_count(minimum_support, length(transactions))
    if implementation != :basic && implementation != :optimized
        throw(ArgumentError("Unknown implementation."))
    end
    nonempty_transactions = Transactions()
    for transaction in transactions
        if !isempty(transaction)
            push!(nonempty_transactions, transaction)
        end
    end
    if length(nonempty_transactions) < minimum_count
        return MiningResult()
    end
    if implementation == :basic
        return mine_apriori_tid(nonempty_transactions, minimum_count)
    else
        return FrequentItemsetMining.mine_apriori_tid_optimized(nonempty_transactions, minimum_count)
    end
end
