# Giữ lệnh chạy test cũ để tương thích với hướng dẫn trước đó.
project_directory = dirname(@__DIR__)
test_path = joinpath(project_directory, "tests", "runtests.jl")
julia_command = Base.julia_cmd()
run(`$julia_command --startup-file=no --project=$project_directory $test_path`)
