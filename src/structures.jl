# Một giao dịch chứa danh sách mã của các item.
# Ví dụ: [1, 2, 3]
const Transaction = Vector{Int}

# Cơ sở dữ liệu gồm nhiều giao dịch.
# Hai giao dịch giống nhau vẫn được giữ riêng.
# Ví dụ: [[1, 2], [1, 2], [2, 3]]
const Transactions = Vector{Transaction}

# Một tập item được biểu diễn bằng Tuple để làm khóa của Dict.
# Ví dụ: (1, 2)
# Vararg{Int}: Tuple có thể chứa nhiều số nguyên
const Itemset = Tuple{Vararg{Int}}

# Kết quả: mỗi tập item được gắn với số giao dịch chứa nó.
# Ví dụ: Dict((1, 2) => 3)
const MiningResult = Dict{Itemset, Int}
