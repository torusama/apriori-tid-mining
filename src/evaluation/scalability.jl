function measure_scalability(io, transactions, fractions, seed, minimum_support, repetitions)
    permutation = randperm(MersenneTwister(seed), length(transactions))
    for fraction in fractions
        count = max(1, round(Int, fraction * length(transactions)))
        sample = transactions[sort(permutation[1:count])]
        for implementation in JULIA_IMPLEMENTATIONS
            run = measure_mining(sample, minimum_support, implementation, repetitions)
            write_csv_row(io, fraction, count, minimum_support, implementation,
                          run.milliseconds, length(run.result))
        end
    end
end

function measure_transaction_width(io, count, items, widths, seed, minimum_support, repetitions)
    rng = MersenneTwister(seed)
    baskets = [randperm(rng, items) for _ in 1:count]
    for width in widths
        sample = [sort(basket[1:width]) for basket in baskets]
        for implementation in JULIA_IMPLEMENTATIONS
            run = measure_mining(sample, minimum_support, implementation, repetitions)
            write_csv_row(io, width, count, items, minimum_support, implementation,
                          run.milliseconds, length(run.result))
        end
    end
end
