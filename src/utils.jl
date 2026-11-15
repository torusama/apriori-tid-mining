# Chuẩn hóa một giao dịch.
# - Kiểm tra giao dịch không rỗng.
# - Mỗi mã item phải là số nguyên dương.
# - Xóa các item trùng nhau trong cùng giao dịch.
# - Sắp xếp các item theo thứ tự tăng dần.
function normalize_transaction(items::Vector{Int})::Transaction
    if isempty(items)
        throw(ArgumentError("Transaction cannot be empty."))
    end

    for item in items
        if item <= 0
            throw(ArgumentError("Item IDs must be positive integers."))
        end
    end

    unique_items = unique(items)
    sorted_items = sort(unique_items)

    return sorted_items
end


# Chuẩn hóa tất cả các giao dịch trong cơ sở dữ liệu.
# Không xóa hai giao dịch có cùng nội dung, vì mỗi giao dịch
# đều được tính riêng khi đếm support.
function normalize_transactions(transactions::Transactions)::Transactions
    normalized_transactions = Transactions()

    for transaction in transactions
        normalized_transaction = normalize_transaction(transaction)
        push!(normalized_transactions, normalized_transaction)
    end

    return normalized_transactions
end


# Kiểm tra cơ sở dữ liệu đã đúng quy ước hay chưa.
# Nếu hợp lệ thì trả về nothing; nếu sai thì thông báo lỗi bằng tiếng Anh.
function validate_transactions(transactions::Transactions)
    if isempty(transactions)
        throw(ArgumentError("Database must contain at least one transaction."))
    end

    for (transaction_index, transaction) in enumerate(transactions)
        if isempty(transaction)
            throw(ArgumentError("Transaction $(transaction_index) is empty."))
        end

        for item in transaction
            if item <= 0
                throw(ArgumentError("Transaction $(transaction_index) contains an invalid item ID."))
            end
        end

        if !issorted(transaction)
            throw(ArgumentError("Transaction $(transaction_index) must be sorted in ascending order."))
        end

        if length(unique(transaction)) != length(transaction)
            throw(ArgumentError("Transaction $(transaction_index) contains duplicate items."))
        end
    end

    return nothing
end


# Chuyển minimum support dạng tỷ lệ thành số lần xuất hiện tối thiểu.
# Ví dụ: Có 5 giao dịch, minimum_support = 0.4 thì kết quả là 2.
# Công thức: ceil(minimum_support * number_of_transactions).
function calculate_minimum_support_count(
    minimum_support::Real,
    number_of_transactions::Int
)::Int
    if !isfinite(minimum_support) || minimum_support <= 0 || minimum_support > 1
        throw(ArgumentError("Minimum support must be greater than 0 and at most 1."))
    end

    if number_of_transactions <= 0
        throw(ArgumentError("Number of transactions must be greater than 0."))
    end

    minimum_support_count = ceil(Int, minimum_support * number_of_transactions)
    return minimum_support_count
end