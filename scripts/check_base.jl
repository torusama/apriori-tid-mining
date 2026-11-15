using FrequentItemsetMining

# Mỗi mảng là một giao dịch ví dụ.
transactions = [
    [1, 2, 3],
    [2, 1],
    [1, 3],
    [2, 3],
    [1, 2, 3]
]

# Chuẩn hóa các giao dịch, nhưng không xóa các giao dịch trùng nhau.
normalized_transactions = normalize_transactions(transactions)
validate_transactions(normalized_transactions)

# Chuyển minimum support dạng tỷ lệ thành số lần xuất hiện tối thiểu.
minimum_support = 0.4
number_of_transactions = length(normalized_transactions)
minimum_support_count = calculate_minimum_support_count(
    minimum_support,
    number_of_transactions
)

# In dữ liệu và kết quả ra màn hình bằng tiếng Anh.
println("Normalized transactions:")
for transaction in normalized_transactions
    println(transaction)
end

println("Number of transactions: ", number_of_transactions)
println("Minimum support: ", minimum_support)
println("Minimum support count: ", minimum_support_count)
println("Base setup completed. Apriori-TID will be implemented in TASK 01.")