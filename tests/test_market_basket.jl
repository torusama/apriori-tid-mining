using FrequentItemsetMining: association_rules, read_groceries, run_market_basket

@testset "Groceries mapping and association-rule metrics" begin
    mktempdir() do directory
        labels_path = joinpath(directory, "labels.txt")
        data_path = joinpath(directory, "data.txt")
        write(labels_path, "010\tbeef\tB\n020\tapples\tA\n030\tbeef\tC\n")
        write(data_path, "2 1 1\n1 1 0\n0 1 0\n0 0 1\n")

        transactions, labels = read_groceries(data_path, labels_path)
        @test labels == ["apples", "beef"]
        @test transactions == [[1, 2], [1, 2], [1], [2]]
        itemsets = mine(transactions; minimum_support = 0.5, implementation = :optimized)
        rules = association_rules(itemsets, 4; minconf = 2 // 3)
        @test length(rules) == 2
        @test rules[1].antecedent == (1,)
        @test rules[1].consequent == (2,)
        @test rules[1].support_count == 2
        @test rules[1].support == 1 // 2
        @test rules[1].confidence == 2 // 3
        @test rules[1].lift == 8 // 9
        @test isempty(association_rules(itemsets, 4; minconf = 0.7))

        output = joinpath(directory, "result")
        summary = run_market_basket(data_path, labels_path, output; minimum_support = 0.5)
        @test summary.duplicate_baskets == 1
        @test read_transactions(joinpath(output, "groceries_spmf.txt")) == transactions
        @test occursin("\"apples\",\"beef\",2,", read(joinpath(output, "top10_rules.csv"), String))
    end

    itemsets = mine([[1, 2, 3]]; minimum_support = 1.0)
    rules = association_rules(itemsets, 1; minconf = 1.0)
    @test length(rules) == 12
    @test any(rule -> rule.antecedent == (1, 2) && rule.consequent == (3,), rules)
end
