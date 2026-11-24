using Downloads
using CodecZlib
using SHA

const FIMI_URL = "https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data"
const GROCERIES_URL = "https://raw.githubusercontent.com/mhahsler/arules/master/data_src/Groceries"
const BENCHMARK_DATASETS = [
    ("chess", 3196, 75),
    ("mushroom", 8124, 119),
    ("retail", 88162, 16470),
    ("T10I4D100K", 100000, 870)
]

# SHA-256 của dữ liệu chuẩn hóa đã dùng trong benchmark trước.
const BENCHMARK_CHECKSUMS = Dict(
    "chess" => "341d0ff8676e053dd3b417d61f84c732736154f987ce56975a099b07460957f5",
    "mushroom" => "06206c73983251a9488414c4379a030e836bbeb6fe9eff1b5624a0193a811640",
    "retail" => "417563fb5feb3711d4f761230ca78b76d100fe2ee0d3178fcc4fbb000d8d1c36",
    "T10I4D100K" => "fb2dd118ff822ff88d724e47d5a4cea6531c0bd6294397db4d36890c1450f1a7",
)

# Chỉ tải khi chưa có file; không giữ file tải dở.
function download_dataset(url, destination)
    mkpath(dirname(destination))
    if !isfile(destination)
        temporary_path = destination * ".download"
        try
            Downloads.download(url, temporary_path; timeout = 120)
            mv(temporary_path, destination; force = true)
        finally
            if isfile(temporary_path)
                rm(temporary_path)
            end
        end
    end
    return destination
end

function read_benchmark_source(source_path)
    contents = read(source_path)
    # Một số máy chủ trả dữ liệu gzip dù đường dẫn có đuôi .dat.
    if length(contents) >= 2 && contents[1] == 0x1f && contents[2] == 0x8b
        contents = transcode(GzipDecompressor, contents)
    end
    return String(contents)
end

function prepare_benchmark(root_directory)
    benchmark_directory = joinpath(root_directory, "benchmark")
    for (name, expected_transactions, expected_items) in BENCHMARK_DATASETS
        source_path = joinpath(benchmark_directory, name * ".dat")
        download_dataset("$FIMI_URL/$name.dat", source_path)
        transactions = Vector{Int}[]
        unique_items = Set{Int}()
        for line in eachline(IOBuffer(read_benchmark_source(source_path)))
            transaction = sort!(unique(parse.(Int, split(line))))
            if isempty(transaction)
                error("$name contains an empty transaction.")
            end
            if minimum(transaction) < 0
                error("$name contains a negative item ID.")
            end
            push!(transactions, transaction)
            union!(unique_items, transaction)
        end
        if length(transactions) != expected_transactions || length(unique_items) != expected_items
            error("$name has an unexpected dataset shape.")
        end
        item_offset = 0 in unique_items ? 1 : 0
        output_path = joinpath(benchmark_directory, name * ".txt")
        temporary_output = output_path * ".download"
        try
            open(temporary_output, "w") do output_file
                for transaction in transactions
                    println(output_file, join(transaction .+ item_offset, ' '))
                end
            end
            checksum = bytes2hex(open(sha256, temporary_output))
            if checksum != BENCHMARK_CHECKSUMS[name]
                error("$name differs from the recorded benchmark (SHA-256: $checksum). Check the source before using it.")
            end
            mv(temporary_output, output_path; force = true)
            println("$name: $(length(transactions)) transactions, $(length(unique_items)) items, ID offset $item_offset, SHA-256 verified")
        finally
            if isfile(temporary_output)
                rm(temporary_output)
            end
        end
    end
end

function prepare_groceries(root_directory)
    for filename in ("Groceries.data", "Groceries.labels")
        download_dataset("$GROCERIES_URL/$filename", joinpath(root_directory, "groceries", filename))
    end
end

function main(arguments = ARGS)
    if !(length(arguments) in (1, 3)) || !(arguments[1] in ("benchmark", "groceries", "all"))
        error("Usage: fetch_datasets.jl benchmark|groceries|all [--root directory]")
    end
    root_directory = "data/raw"
    if length(arguments) == 3
        arguments[2] == "--root" || error("Expected --root.")
        root_directory = arguments[3]
    end
    if arguments[1] in ("benchmark", "all")
        prepare_benchmark(root_directory)
    end
    if arguments[1] in ("groceries", "all")
        prepare_groceries(root_directory)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
