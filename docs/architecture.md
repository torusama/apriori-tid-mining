# Project 02 - System Architecture (Julia)

## Goal

Use one team-implemented Apriori-TID algorithm for performance evaluation and both applications. SPMF serves only as a reference for correctness and benchmark comparisons.

## Source Modules

- `src/algorithm/`: candidate generation, Apriori-TID, and SPMF input/output.
- `src/evaluation/`: SPMF comparisons, runtime, memory, and scalability.
- `src/applications/`: Groceries market basket analysis and Flowers-17 visual pattern mining.

## Data Flow

Raw data -> Transaction preprocessing -> Apriori-TID -> Frequent itemsets -> Evaluation or applications -> Results and report.

## Base Files

- `src/structures.jl`: shared data types.
- `src/utils.jl`: transaction normalization, validation, and minimum support threshold.
- `src/algorithm/api.jl`: public `mine()` interface.
- `src/FrequentItemsetMining.jl`: Julia module entry point and `include()` declarations.
- `tests/runtests.jl`: main Julia test entry point.
- `scripts/check_base.jl`: standalone Base demonstration without mining.

## Integration Rules

1. Preserve duplicate transactions as separate records when counting support.
2. Item IDs must be positive integers.
3. Support count means the number of transactions containing an itemset.
4. Transactions and itemsets use sorted, unique item IDs.
5. Applications and evaluation use the shared `mine()` API.
6. Do not import a ready-made frequent itemset mining algorithm.
7. Keep evaluation, visualization, and image dependencies in their dedicated Julia environments.
