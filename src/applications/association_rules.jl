struct AssociationRule
    antecedent::Itemset
    consequent::Itemset
    support_count::Int
    support::Rational{Int}
    confidence::Rational{Int}
    lift::Rational{Int}
end

function each_rule_split!(visit, itemset::Itemset, index::Int, left::Vector{Int}, right::Vector{Int})
    if index > length(itemset)
        if !isempty(left) && !isempty(right)
            visit(Tuple(left), Tuple(right))
        end
        return
    end

    push!(left, itemset[index])
    each_rule_split!(visit, itemset, index + 1, left, right)
    pop!(left)
    push!(right, itemset[index])
    each_rule_split!(visit, itemset, index + 1, left, right)
    pop!(right)
    return
end

function association_rules(itemsets::MiningResult, transaction_count::Int; minconf::Real)
    transaction_count > 0 || throw(ArgumentError("Transaction count must be positive."))
    0 < minconf <= 1 || throw(ArgumentError("Minimum confidence must be in (0, 1]."))
    minimum_confidence = minconf isa AbstractFloat ? rationalize(minconf) : minconf

    rules = AssociationRule[]
    for (itemset, count) in itemsets
        length(itemset) < 2 && continue
        support = count // transaction_count
        each_rule_split!(itemset, 1, Int[], Int[]) do antecedent, consequent
            confidence = count // itemsets[antecedent]
            if confidence >= minimum_confidence
                lift = confidence / (itemsets[consequent] // transaction_count)
                push!(rules, AssociationRule(antecedent, consequent, count, support, confidence, lift))
            end
        end
    end

    sort!(rules; by = rule -> (
        -rule.lift, -rule.support_count, -rule.confidence, rule.antecedent, rule.consequent
    ))
    return rules
end
