using Test
using FrequentItemsetMining

# Chạy kiểm thử các hàm Base của TASK 00.
include(joinpath(@__DIR__, "..", "tests", "test_contract.jl"))

# Chạy kiểm thử sinh ứng viên và cấu trúc Apriori-TID.
include(joinpath(@__DIR__, "..", "tests", "test_apriori_tid.jl"))

# Chạy kiểm thử kết quả khai thác tập phổ biến.
include(joinpath(@__DIR__, "..", "tests", "test_correctness.jl"))

# Chạy kiểm thử đọc, ghi file và CLI.
include(joinpath(@__DIR__, "..", "tests", "test_io.jl"))

# Chạy kiểm thử công cụ đối chiếu SPMF.
include(joinpath(@__DIR__, "..", "tests", "test_spmf.jl"))
include(joinpath(@__DIR__, "..", "tests", "test_market_basket.jl"))
