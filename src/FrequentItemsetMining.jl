module FrequentItemsetMining

# Nạp các kiểu dữ liệu chung.
include("structures.jl")

# Nạp các hàm kiểm tra và chuẩn hóa giao dịch.
include("utils.jl")

# Nạp hàm sinh và lọc tập ứng viên.
include("algorithm/candidate_generation.jl")

# Nạp thuật toán Apriori-TID cơ bản.
include("algorithm/apriori_tid.jl")

# Nạp hàm đọc và ghi dữ liệu SPMF.
include("algorithm/spmf_io.jl")

# Nạp hàm giao diện chung để chạy thuật toán.
include("algorithm/api.jl")

# Nạp các hàm so sánh kết quả với SPMF.
include("evaluation/compare_spmf.jl")

# Phiên bản tối ưu sẽ được bổ sung trong TASK 03.
# include("algorithm/apriori_tid_optimized.jl")


# Cho phép các file bên ngoài sử dụng các kiểu dữ liệu.
export Transaction, Transactions, Itemset, MiningResult

# Cho phép sử dụng các hàm chuẩn hóa và kiểm tra dữ liệu.
export normalize_transaction
export normalize_transactions
export validate_transactions
export calculate_minimum_support_count

# Cho phép sử dụng các hàm sinh ứng viên.
export has_infrequent_subset
export generate_candidates

# Cho phép sử dụng thuật toán Apriori-TID.
export build_level_one
export build_candidate_records
export mine_apriori_tid
export mine

# Cho phép sử dụng các hàm đọc và ghi dữ liệu.
export read_transactions
export write_itemsets
export read_itemsets

# Cho phép sử dụng các hàm so sánh SPMF.
export run_spmf
export compare_results
export print_comparison

end