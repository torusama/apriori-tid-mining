struct AssociationRule
    antecedent::Itemset
    consequent::Itemset
    support_count::Int
    support::Rational{Int}
    confidence::Rational{Int}
    lift::Rational{Int}
end

# Chia từng item vào một trong hai vế của luật; mỗi vế phải khác rỗng.
function each_rule_split!(visit_rule, itemset::Itemset, item_position::Int,
                          antecedent_items::Vector{Int}, consequent_items::Vector{Int})
    if item_position > length(itemset)
        if !isempty(antecedent_items) && !isempty(consequent_items)
            visit_rule(Tuple(antecedent_items), Tuple(consequent_items))
        end
        return
    end

    item = itemset[item_position]
    # Nhánh 1: đưa item hiện tại vào vế trái.
    push!(antecedent_items, item)
    each_rule_split!(visit_rule, itemset, item_position + 1, antecedent_items, consequent_items)
    pop!(antecedent_items)

    # Nhánh 2: đưa item hiện tại vào vế phải.
    push!(consequent_items, item)
    each_rule_split!(visit_rule, itemset, item_position + 1, antecedent_items, consequent_items)
    pop!(consequent_items)
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
