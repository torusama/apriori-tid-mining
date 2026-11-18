"""Render benchmark and market-basket plots from the generated CSV files."""

import argparse
import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


SERIES = {"basic": ("#2C5A87", "o"), "optimized": ("#087F6C", "s"), "spmf": ("#A35B15", "^")}


def read_rows(directory, filename):
    with (directory / filename).open(newline="", encoding="utf-8") as source:
        return list(csv.DictReader(source))


def series(axis, rows, x, y, implementations):
    for implementation in implementations:
        samples = [row for row in rows if row["implementation"] == implementation]
        color, marker = SERIES[implementation]
        axis.plot(
            [float(row[x]) for row in samples], [float(row[y]) for row in samples],
            marker=marker, color=color, linewidth=1.6, label=implementation,
        )


def save(figure, path):
    figure.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(figure)


def benchmark_plots(directory):
    runs = read_rows(directory, "benchmarks.csv")
    datasets = list(dict.fromkeys(row["dataset"] for row in runs))
    if len(datasets) != 4:
        raise ValueError("Plots require four benchmark datasets")

    for metric, label, implementations in (
        ("runtime_ms", "Runtime (ms)", tuple(SERIES)),
        ("itemsets", "Frequent itemsets", ("optimized",)),
    ):
        figure, axes = plt.subplots(2, 2, figsize=(9, 6.4), layout="constrained")
        for dataset, axis in zip(datasets, axes.flat):
            dataset_runs = [row for row in runs if row["dataset"] == dataset]
            series(axis, dataset_runs, "minsup", metric, implementations)
            axis.set(title=dataset.capitalize() if dataset.islower() else dataset,
                     xlabel="Minimum support", ylabel=label)
            thresholds = list(dict.fromkeys(float(row["minsup"]) for row in dataset_runs))
            axis.set_xticks(thresholds, labels=[f"{100 * threshold:.4g}%" for threshold in thresholds])
            axis.invert_xaxis()
            axis.grid(axis="y", alpha=0.2)
            if metric == "runtime_ms":
                if all(float(row[metric]) > 0 for row in dataset_runs):
                    axis.set_yscale("log")
                else:
                    axis.set_yscale("symlog", linthresh=1)
                    axis.set_ylim(bottom=0)
        if metric == "runtime_ms":
            axes[0, 0].legend(frameon=False)
        save(figure, directory / f"{metric}.png")

    memory = read_rows(directory, "peak_ram.csv")
    figure, axis = plt.subplots(figsize=(8, 4), layout="constrained")
    for implementation, offset in (("basic", -0.17), ("optimized", 0.17)):
        samples = {row["dataset"]: row for row in memory if row["implementation"] == implementation}
        axis.bar([index + offset for index in range(len(datasets))],
                 [int(samples[name]["peak_rss_bytes"]) / 2**20 for name in datasets],
                 width=0.34, label=implementation, color=SERIES[implementation][0])
    axis.set(xticks=range(len(datasets)), xticklabels=datasets, ylabel="Peak RSS (MiB)")
    axis.legend(frameon=False)
    save(figure, directory / "peak_ram.png")

    figure, axes = plt.subplots(1, 2, figsize=(10, 4), layout="constrained")
    for axis, filename, field, label, title in (
        (axes[0], "scalability.csv", "transactions", "Transactions", "Retail scaling"),
        (axes[1], "transaction_width.csv", "width", "Items per transaction", "Synthetic transaction width"),
    ):
        series(axis, read_rows(directory, filename), field, "runtime_ms", ("basic", "optimized"))
        axis.set(title=title, xlabel=label, ylabel="Median runtime (ms)")
        axis.grid(axis="y", alpha=0.2)
        axis.legend(frameon=False)
    save(figure, directory / "scaling_and_width.png")


def groceries_plots(directory):
    figure, axis = plt.subplots(figsize=(7, 3.5), layout="constrained")
    widths = read_rows(directory, "basket_lengths.csv")
    axis.bar([int(row["items"]) for row in widths], [int(row["baskets"]) for row in widths], color="#2C5A87")
    axis.set(xlabel="Distinct categories per basket", ylabel="Baskets")
    save(figure, directory / "basket_lengths.png")

    rules = read_rows(directory, "top10_rules.csv")
    figure, axis = plt.subplots(figsize=(9, 5.3), layout="constrained")
    bars = axis.barh([f'{row["antecedent"]} → {row["consequent"]}' for row in rules],
                     [float(row["lift"]) for row in rules], color="#087F6C")
    axis.bar_label(bars, fmt="%.2f", padding=4)
    if rules:
        axis.set_xlim(0, 1.16 * max(float(row["lift"]) for row in rules))
    axis.axvline(1, linestyle=":", linewidth=1, color="#333333")
    axis.set(xlabel="Lift")
    axis.invert_yaxis()
    save(figure, directory / "top10_rules.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kind", choices=("benchmark", "groceries"))
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    if args.kind == "benchmark":
        benchmark_plots(args.directory)
    else:
        groceries_plots(args.directory)
