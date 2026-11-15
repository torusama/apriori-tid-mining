# Project 02 - Apriori-TID API Contract (Julia)

## Input Data

- `Transaction = Vector{Int}` represents a single transaction.
- `Transactions = Vector{Vector{Int}}` represents the transaction database.
- Transaction item IDs are positive integers, sorted in ascending order, without repeated items.
- Duplicate transactions are preserved and counted separately.

## Minimum Support

Use `calculate_minimum_support_count(minimum_support, number_of_transactions)`.

Example: five transactions and relative minimum support of `0.4` produce an absolute threshold of `2`.

## Output Data

`MiningResult = Dict{Tuple{Vararg{Int}}, Int}` maps an itemset to its absolute support count.

Example: `(1, 2) => 3` means that itemset `{1, 2}` appears in three transactions.

## Public API

```julia
mine(transactions; minimum_support=0.4, implementation=:basic)
```

- `:basic`: basic Apriori-TID implementation (TASK 01).
- `:optimized`: optimized Apriori-TID implementation (TASK 03).
- The Base version only validates inputs and raises a clear not-implemented error.

## SPMF Input and Output (TASK 01)

Input: one transaction per line, with space-separated item IDs.

Output example: `1 2 #SUP: 3`.

## Integration Rules

- Benchmarking and both applications call the same `mine()` function.
- Keep API changes coordinated across team members.
- Complete toy-data tests before running large benchmarks.