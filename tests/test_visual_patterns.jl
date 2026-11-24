using Test
using FrequentItemsetMining
include(joinpath(@__DIR__, "..", "src", "applications", "visual_patterns.jl"))

@testset "Visual patterns preserve empty image transactions" begin
    mktempdir() do directory
        file_path = joinpath(directory, "transactions.txt")
        write(file_path, "1 2\n\n1 3\n1 2\n")
        transactions = read_visual_transactions(file_path)
        @test transactions == [[1, 2], Int[], [1, 3], [1, 2]]
        expected = MiningResult((1,) => 3, (2,) => 2, (1, 2) => 2)
        @test mine_visual_transactions(transactions, 0.5) == expected
        @test mine_visual_transactions(transactions, 0.5; implementation=:optimized) == expected
        @test isempty(mine_visual_transactions(transactions, 1.0))
        @test isempty(mine_visual_transactions([Int[], Int[]], 0.5))
        @test_throws ArgumentError mine_visual_transactions(transactions, 0.0)
        nonempty_path = joinpath(directory, "nonempty.txt")
        write_transactions(nonempty_path, [[1, 2], [1, 3], [1, 2]])
        @test read_visual_transactions(nonempty_path) == read_transactions(nonempty_path)
        for (itemset, support) in expected
            independent_count = count(transaction -> all(item -> item in transaction, itemset), transactions)
            @test support == independent_count
        end
    end
end
