using CSV
# GR vẽ được PNG không cần giao diện đồ họa, kể cả trên Colab.
ENV["GKSwstype"] = "100"
using Plots

function read_rows(directory, filename)
    return collect(CSV.File(joinpath(directory, filename)))
end

function plot_benchmark_series(rows, horizontal_field, vertical_field, implementations;
                               title_text = "", horizontal_label = "", vertical_label = "",
                               reverse_axis = false)
    figure = plot(title = title_text, xlabel = horizontal_label, ylabel = vertical_label,
                  xflip = reverse_axis, legend = :best, grid = true)
    for implementation in implementations
        selected_rows = filter(row -> row.implementation == implementation, rows)
        horizontal_values = [getproperty(row, horizontal_field) for row in selected_rows]
        vertical_values = [getproperty(row, vertical_field) for row in selected_rows]
        plot!(figure, horizontal_values, vertical_values; label = implementation,
              marker = :circle, linewidth = 2)
    end
    return figure
end

function benchmark_plots(directory)
    rows = read_rows(directory, "benchmarks.csv")
    datasets = unique([row.dataset for row in rows])
    for (field, label, implementations) in (
        (:runtime_ms, "Runtime (ms)", ("basic", "optimized", "spmf")),
        (:itemsets, "Frequent itemsets", ("optimized",))
    )
        figures = []
        for dataset in datasets
            dataset_rows = filter(row -> row.dataset == dataset, rows)
            figure = plot_benchmark_series(dataset_rows, :minsup, field, implementations;
                title_text = dataset, horizontal_label = "Minimum support", vertical_label = label,
                reverse_axis = true)
            push!(figures, figure)
        end
        combined_figure = plot(figures...; layout = (2, 2), size = (1100, 800), dpi = 150)
        savefig(combined_figure, joinpath(directory, string(field) * ".png"))
    end

    memory_rows = read_rows(directory, "peak_ram.csv")
    memory_figure = plot(ylabel = "Peak RSS (MiB)", xticks = (1:length(datasets), datasets),
                         size = (900, 500), legend = :topright)
    for (implementation, offset) in (("basic", -0.18), ("optimized", 0.18))
        selected_rows = filter(row -> row.implementation == implementation, memory_rows)
        memory_by_dataset = Dict(row.dataset => row.peak_rss_bytes for row in selected_rows)
        memory_values = [memory_by_dataset[dataset] / 2^20 for dataset in datasets]
        bar!(memory_figure, collect(1:length(datasets)) .+ offset, memory_values;
             bar_width = 0.35, label = implementation)
    end
    savefig(memory_figure, joinpath(directory, "peak_ram.png"))

    scaling_figure = plot_benchmark_series(read_rows(directory, "scalability.csv"),
        :transactions, :runtime_ms, ("basic", "optimized"); title_text = "Retail scaling",
        horizontal_label = "Transactions", vertical_label = "Runtime (ms)")
    width_figure = plot_benchmark_series(read_rows(directory, "transaction_width.csv"),
        :width, :runtime_ms, ("basic", "optimized"); title_text = "Transaction width",
        horizontal_label = "Items per transaction", vertical_label = "Runtime (ms)")
    combined_figure = plot(scaling_figure, width_figure; layout = (1, 2), size = (1100, 450))
    savefig(combined_figure, joinpath(directory, "scaling_and_width.png"))
end

function groceries_plots(directory)
    widths = read_rows(directory, "basket_lengths.csv")
    basket_figure = bar([row.items for row in widths], [row.baskets for row in widths];
        xlabel = "Distinct categories per basket", ylabel = "Baskets", legend = false, size = (900, 450))
    savefig(basket_figure, joinpath(directory, "basket_lengths.png"))

    rules = read_rows(directory, "top10_rules.csv")
    if isempty(rules)
        println("No association rules to plot.")
        return
    end
    rule_labels = [string(row.antecedent, " -> ", row.consequent) for row in rules]
    lift_values = [row.lift for row in rules]
    rule_figure = bar(1:length(rules), lift_values; orientation = :horizontal,
        yticks = (1:length(rules), rule_labels), yflip = true, xlabel = "Lift",
        legend = false, size = (1200, 600), left_margin = 65 * Plots.mm)
    vline!(rule_figure, [1]; label = "", linestyle = :dash)
    savefig(rule_figure, joinpath(directory, "top10_rules.png"))
end
