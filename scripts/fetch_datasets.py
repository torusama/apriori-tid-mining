"""Download project datasets and write normalized SPMF benchmark files."""

import argparse
import gzip
from pathlib import Path
from urllib.request import urlopen


FIMI = "https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data"
ARULES = "https://raw.githubusercontent.com/mhahsler/arules/master/data_src/Groceries"
BENCHMARKS = {
    "chess": (3196, 75),
    "mushroom": (8124, 119),
    "retail": (88162, 16470),
    "T10I4D100K": (100000, 870),
}


def fetch(url, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.is_file():
        with urlopen(url, timeout=40) as response:
            contents = response.read()
        destination.write_bytes(contents)
    return destination.read_bytes()


def prepare_benchmark(root):
    destination = root / "benchmark"
    for name, expected_shape in BENCHMARKS.items():
        raw = fetch(f"{FIMI}/{name}.dat", destination / f"{name}.dat")
        contents = gzip.decompress(raw) if raw.startswith(b"\x1f\x8b") else raw
        transactions = [sorted(set(map(int, line.split()))) for line in contents.splitlines()]
        if any(not transaction for transaction in transactions):
            raise ValueError(f"{name}: the source contains an empty transaction")
        items = {item for transaction in transactions for item in transaction}
        if (len(transactions), len(items)) != expected_shape or min(items) < 0:
            raise ValueError(f"{name}: unexpected dataset shape or item IDs")
        offset = int(0 in items)
        path = destination / f"{name}.txt"
        with path.open("w", encoding="ascii") as output:
            for transaction in transactions:
                output.write(" ".join(str(item + offset) for item in transaction) + "\n")
        print(f"{name}: {len(transactions)} transactions, {len(items)} items, ID offset {offset}")


def prepare_groceries(root):
    for filename in ("Groceries.data", "Groceries.labels"):
        fetch(f"{ARULES}/{filename}", root / "groceries" / filename)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dataset", choices=("benchmark", "groceries", "all"))
    parser.add_argument("--root", type=Path, default=Path("data/raw"))
    args = parser.parse_args()
    if args.dataset in ("benchmark", "all"):
        prepare_benchmark(args.root)
    if args.dataset in ("groceries", "all"):
        prepare_groceries(args.root)
