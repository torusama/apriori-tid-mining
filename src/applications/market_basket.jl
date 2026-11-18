# The arules matrix has one quantity column per label. FIM uses item presence.
function read_groceries(data_path::AbstractString, labels_path::AbstractString)
    column_labels = map(readlines(labels_path)) do line
        fields = split(line, '\t'; limit = 3)
        length(fields) == 3 && !isempty(strip(fields[2])) ||
            throw(ArgumentError("Invalid Groceries label: $(repr(line))."))
        String(strip(fields[2]))
    end
    isempty(column_labels) && throw(ArgumentError("No Groceries labels found."))

    labels = sort!(unique(column_labels))
    item_ids = Dict(label => id for (id, label) in enumerate(labels))
    column_ids = [item_ids[label] for label in column_labels]
    transactions = Transactions()
    for (row, line) in enumerate(eachline(data_path))
        values = split(line)
        length(values) == length(column_ids) ||
            throw(ArgumentError("Unexpected column count in Groceries row $row."))
        items = Int[]
        for (column, value) in enumerate(values)
            quantity = tryparse(Int, value)
            if isnothing(quantity) || quantity < 0
                throw(ArgumentError("Expected a nonnegative quantity in Groceries row $row, column $column."))
            end
            if quantity > 0
                push!(items, column_ids[column])
            end
        end
        push!(transactions, normalize_transaction(items))
    end
    validate_transactions(transactions)
    return transactions, labels
end

function write_item_mapping(path::AbstractString, labels::Vector{String})
    open(path, "w") do io
        println(io, "{")
        for (id, label) in enumerate(labels)
            # Encode control characters using the JSON Unicode escape.
            escaped = join(map(collect(label)) do char
                if char == '"' || char == '\\'
                    string('\\', char)
                elseif char < ' '
                    "\\u" * string(Int(char); base = 16, pad = 4)
                else
                    string(char)
                end
            end)
            println(io, "  \"$id\": \"$escaped\"", id == length(labels) ? "" : ",")
        end
        println(io, "}")
    end
end

function write_rules(path::AbstractString, rules::AbstractVector{AssociationRule}, labels::Vector{String})
    csv_field(value) = "\"" * replace(value, "\"" => "\"\"") * "\""
    open(path, "w") do io
        println(io, "antecedent,consequent,support_count,support,confidence,lift")
        for rule in rules
            println(io, join((
                csv_field(join(labels[collect(rule.antecedent)], " + ")),
                csv_field(join(labels[collect(rule.consequent)], " + ")),
                rule.support_count, Float64(rule.support), Float64(rule.confidence), Float64(rule.lift)
            ), ','))
        end
    end
end

function run_market_basket(data_path, labels_path, output_dir;
                          minimum_support = 0.01, minconf = 0.4, implementation = :optimized)
    transactions, labels = read_groceries(data_path, labels_path)
    itemsets = mine(transactions; minimum_support, implementation)
    rules = association_rules(itemsets, length(transactions); minconf)
    top_rules = first(rules, min(10, length(rules)))

    mkpath(output_dir)
    write_transactions(joinpath(output_dir, "groceries_spmf.txt"), transactions)
    write_item_mapping(joinpath(output_dir, "item_mapping.json"), labels)
    write_itemsets(joinpath(output_dir, "frequent_itemsets.txt"), itemsets)
    write_rules(joinpath(output_dir, "rules.csv"), rules, labels)
    write_rules(joinpath(output_dir, "top10_rules.csv"), top_rules, labels)

    widths = length.(transactions)
    open(joinpath(output_dir, "basket_lengths.csv"), "w") do io
        println(io, "items,baskets")
        for width in sort!(unique(widths))
            println(io, width, ',', count(==(width), widths))
        end
    end
    summary = (; transactions = length(transactions), items = length(labels),
               duplicate_baskets = length(transactions) - length(unique(transactions)),
               mean_basket_length = sum(widths) / length(widths),
               minimum_support, minconf, implementation = string(implementation),
               itemsets = length(itemsets), rules = length(rules))
    open(joinpath(output_dir, "summary.toml"), "w") do io
        for (key, value) in pairs(summary)
            println(io, key, " = ", repr(value))
        end
    end
    return summary
end
