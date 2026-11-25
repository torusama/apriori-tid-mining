using Test
using FrequentItemsetMining

project_directory = dirname(@__DIR__)
if !(isempty(ARGS) || ARGS == ["--core-only"])
    error("Usage: julia --project=. test/runtests.jl [--core-only]")
end
core_only = ARGS == ["--core-only"]
if core_only
    println("Core-only mode: SPMF integration and image integration are not required in this run.")
else
    jar_path = get(ENV, "SPMF_JAR", joinpath(project_directory, "tools", "spmf.jar"))
    isfile(jar_path) || error("SPMF JAR not found: $jar_path")
    Sys.which("java") !== nothing || error("Java 25+ is required for the bundled SPMF JAR.")
    java_version = read(`java --version`, String)
    java_major = match(r"(?:openjdk|java) (\d+)", java_version)
    if isnothing(java_major) || parse(Int, java_major.captures[1]) < 25
        error("Java 25+ is required for the bundled SPMF JAR. Found: $java_version")
    end
    ENV["SPMF_JAR"] = abspath(jar_path)
end

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
include(joinpath(@__DIR__, "..", "tests", "test_visual_patterns.jl"))

if !core_only
    image_environment = joinpath(project_directory, "visual_environment")
    image_test_path = joinpath(project_directory, "tests", "test_visual_images.jl")
    julia_command = Base.julia_cmd()
    println("Running image integration tests")
    run(`$julia_command --startup-file=no --project=$image_environment $image_test_path`)
    println("Full test suite completed successfully.")
else
    println("Core tests completed; this is not the full submission test run.")
end
