include(joinpath(@__DIR__, "..", "src", "FrequentItemsetMining.jl"))
using .FrequentItemsetMining
include(joinpath(@__DIR__, "..", "src", "applications", "image_features.jl"))
include(joinpath(@__DIR__, "..", "src", "applications", "visual_codebook.jl"))
include(joinpath(@__DIR__, "..", "src", "applications", "visual_patterns.jl"))

using Random
using Statistics
using TOML
using Dates
using Base64

# Ghi một giá trị CSV và đặt dấu ngoặc kép khi cần thiết.
function escape_csv_field(value)
    text = string(value)
    if occursin(',', text) || occursin('"', text) || occursin('\n', text)
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end

# Ghi tên cột và các dòng dữ liệu vào file CSV.
function save_csv(file_path, column_names, rows)
    open(file_path, "w") do output_file
        println(output_file, join(column_names, ','))
        for row in rows
            fields = String[]
            for value in row
                push!(fields, escape_csv_field(value))
            end
            println(output_file, join(fields, ','))
        end
    end
end

# Tạo codebook và giữ đúng một giao dịch cùng thông tin cho mỗi ảnh.
function prepare_visual_transactions(image_paths, image_directory, output_directory;
                                     maximum_side = 256, maximum_descriptors = 100,
                                     number_of_words = 8, random_seed = 42,
                                     maximum_training_descriptors = 20000)
    random_generator = MersenneTwister(random_seed)
    samples_per_image = max(1, div(maximum_training_descriptors, length(image_paths)))
    # Lượt 1: chỉ giữ một phần descriptor để huấn luyện, tránh giữ toàn bộ ảnh trong RAM.
    training_samples = Matrix{Float32}[]
    for (image_number, image_path) in enumerate(image_paths)
        descriptors, _ = extract_image_descriptors(image_path, maximum_side, maximum_descriptors)
        number_of_descriptors = size(descriptors, 2)
        if number_of_descriptors > 0
            number_of_samples = min(samples_per_image, number_of_descriptors)
            selected_indices = randperm(random_generator, number_of_descriptors)[1:number_of_samples]
            push!(training_samples, descriptors[:, selected_indices])
        end
        if image_number % 100 == 0 || image_number == length(image_paths)
            println("Training descriptors: $(image_number)/$(length(image_paths)) images")
        end
    end
    if isempty(training_samples)
        throw(ArgumentError("No ORB descriptors available for the codebook."))
    end
    training_descriptors = hcat(training_samples...)
    if size(training_descriptors, 2) > maximum_training_descriptors
        selected_indices = randperm(random_generator, size(training_descriptors, 2))[1:maximum_training_descriptors]
        training_descriptors = training_descriptors[:, selected_indices]
    end
    centers = fit_visual_codebook(training_descriptors, number_of_words, random_seed)
    codebook_path = joinpath(output_directory, "codebook.csv")
    save_visual_codebook(codebook_path, centers)
    centers = load_visual_codebook(codebook_path)
    transactions = Transactions()
    # Lượt 2: gán descriptor từng ảnh vào codebook đã huấn luyện.
    records = NamedTuple[]
    for (transaction_id, image_path) in enumerate(image_paths)
        descriptors, details = extract_image_descriptors(image_path, maximum_side, maximum_descriptors)
        transaction = descriptors_to_visual_transaction(descriptors, centers)
        push!(transactions, transaction)
        record = (transaction_id = transaction_id, image_id = splitext(basename(image_path))[1],
                  filename = basename(image_path), relative_path = relpath(image_path, image_directory),
                  status = details.status, height = details.height, width = details.width,
                  num_descriptors = size(descriptors, 2), num_unique_visual_words = length(transaction),
                  error = details.message)
        push!(records, record)
        if transaction_id % 100 == 0 || transaction_id == length(image_paths)
            println("Building transactions: $(transaction_id)/$(length(image_paths)) images")
        end
    end
    transaction_path = joinpath(output_directory, "flowers_spmf.txt")
    open(transaction_path, "w") do output_file
        for transaction in transactions
            println(output_file, join(transaction, ' '))
        end
    end
    mapping_columns = ["transaction_id", "image_id", "filename", "relative_path", "status",
                       "height", "width", "num_descriptors", "num_unique_visual_words", "error"]
    save_csv(joinpath(output_directory, "image_transaction_mapping.csv"), mapping_columns, records)
    if read_visual_transactions(transaction_path) != transactions
        error("Loaded transactions do not match the saved transactions.")
    end
    return transactions, records, size(training_descriptors, 2)
end

# Lưu các tập phổ biến cùng support count và tỉ lệ support.
function save_visual_itemsets(file_path, itemsets, number_of_transactions)
    rows = Tuple{String, Int, Int, Float64}[]
    for itemset in sort!(collect(keys(itemsets)))
        support_count = itemsets[itemset]
        push!(rows, (join(itemset, ' '), length(itemset), support_count,
                     support_count / number_of_transactions))
    end
    save_csv(file_path, ["itemset", "size", "support_count", "support_fraction"], rows)
end

# Chọn các tập phổ biến, kiểm tra support và tạo ảnh minh họa từ ảnh gốc.
function save_pattern_examples(output_directory, image_directory, transactions, records, itemsets)
    candidates = Tuple{Int, Itemset}[]
    for (itemset, support_count) in itemsets
        if 2 <= length(itemset) <= 3
            push!(candidates, (-support_count, itemset))
        end
    end
    sort!(candidates)
    rows = Tuple{String, Int, String}[]
    figures_directory = joinpath(output_directory, "figures")
    mkpath(figures_directory)
    for (example_number, (negative_support, itemset)) in enumerate(first(candidates, min(3, length(candidates))))
        support_count = -negative_support
        matching_indices = Int[]
        for (transaction_id, transaction) in enumerate(transactions)
            contains_itemset = true
            for item in itemset
                if !(item in transaction)
                    contains_itemset = false
                    break
                end
            end
            if contains_itemset
                push!(matching_indices, transaction_id)
            end
        end
        if length(matching_indices) != support_count
            error("Support does not match the number of images containing $(itemset).")
        end
        image_ids = String[]
        for transaction_id in matching_indices
            push!(image_ids, records[transaction_id].image_id)
        end
        example_path = joinpath(figures_directory, "pattern_$(example_number).svg")
        save_image_grid(example_path, image_directory, records, matching_indices, itemset, support_count, length(transactions))
        push!(rows, (join(itemset, ' '), support_count, join(image_ids, ' ')))
    end
    save_csv(joinpath(output_directory, "pattern_examples.csv"), ["itemset", "support_count", "image_ids"], rows)
end

# Chuyển ký tự đặc biệt để tên ảnh hiển thị đúng trong file SVG.
function escape_svg_text(value)
    text = string(value)
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    return replace(text, "\"" => "&quot;")
end

# Lưu tối đa 5 ảnh gốc trong một hình SVG có tên ảnh và support.
function save_image_grid(file_path, image_directory, records, matching_indices, itemset, support_count, image_count)
    image_count_to_show = min(5, length(matching_indices))
    figure_width = image_count_to_show * 240
    open(file_path, "w") do output_file
        println(output_file, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(figure_width)\" height=\"270\">")
        println(output_file, "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>")
        title = escape_svg_text("Itemset $(itemset), support $(support_count)/$(image_count)")
        println(output_file, "<text x=\"10\" y=\"24\" font-size=\"18\">$(title)</text>")
        for index in 1:image_count_to_show
            transaction_id = matching_indices[index]
            image_path = joinpath(image_directory, records[transaction_id].relative_path)
            image_data = base64encode(read(image_path))
            media_type = "image/jpeg"
            if lowercase(splitext(image_path)[2]) == ".png"
                media_type = "image/png"
            end
            position_x = (index - 1) * 240
            println(output_file, "<image x=\"$(position_x)\" y=\"35\" width=\"230\" height=\"200\" preserveAspectRatio=\"xMidYMid meet\" href=\"data:$(media_type);base64,$(image_data)\"/>")
            image_id = escape_svg_text(records[transaction_id].image_id)
            println(output_file, "<text x=\"$(position_x + 10)\" y=\"255\" font-size=\"15\">$(image_id)</text>")
        end
        println(output_file, "</svg>")
    end
end

# Vẽ biểu đồ cột SVG từ tên cột và giá trị thực tế.
function save_bar_chart(file_path, title, labels, values)
    number_of_bars = length(values)
    figure_width = max(600, 80 * number_of_bars + 100)
    maximum_value = 1
    if !isempty(values)
        maximum_value = max(1, maximum(values))
    end
    open(file_path, "w") do output_file
        println(output_file, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$(figure_width)\" height=\"350\">")
        println(output_file, "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>")
        println(output_file, "<text x=\"20\" y=\"25\" font-size=\"18\">$(escape_svg_text(title))</text>")
        println(output_file, "<line x1=\"45\" y1=\"290\" x2=\"$(figure_width - 20)\" y2=\"290\" stroke=\"black\"/>")
        for index in eachindex(values)
            bar_height = round(Int, values[index] * 220 / maximum_value)
            position_x = 60 + (index - 1) * 80
            position_y = 290 - bar_height
            println(output_file, "<rect x=\"$(position_x)\" y=\"$(position_y)\" width=\"45\" height=\"$(bar_height)\" fill=\"steelblue\"/>")
            println(output_file, "<text x=\"$(position_x)\" y=\"$(position_y - 6)\" font-size=\"12\">$(values[index])</text>")
            println(output_file, "<text x=\"$(position_x)\" y=\"312\" font-size=\"12\">$(escape_svg_text(labels[index]))</text>")
        end
        println(output_file, "</svg>")
    end
end

# Vẽ số tập phổ biến, số word mỗi ảnh và số ảnh chứa mỗi word.
function save_visual_figures(output_directory, transactions, support_values, pattern_counts)
    figures_directory = joinpath(output_directory, "figures")
    mkpath(figures_directory)
    save_bar_chart(joinpath(figures_directory, "num_patterns_vs_minsup.svg"),
                   "Frequent itemsets by minimum support", support_values, pattern_counts)
    length_counts = Dict{Int, Int}()
    word_counts = Dict{Int, Int}()
    for transaction in transactions
        transaction_length = length(transaction)
        length_counts[transaction_length] = get(length_counts, transaction_length, 0) + 1
        for word in transaction
            word_counts[word] = get(word_counts, word, 0) + 1
        end
    end
    lengths = sort!(collect(keys(length_counts)))
    length_values = Int[]
    for transaction_length in lengths
        push!(length_values, length_counts[transaction_length])
    end
    save_bar_chart(joinpath(figures_directory, "words_per_image.svg"),
                   "Images by number of visual words", lengths, length_values)
    words = sort!(collect(keys(word_counts)))
    word_values = Int[]
    for word in words
        push!(word_values, word_counts[word])
    end
    save_bar_chart(joinpath(figures_directory, "visual_word_support.svg"),
                   "Images containing each visual word", words, word_values)
end

# Ghi nhận số tập phổ biến và giới hạn khi diễn giải visual word.
function save_visual_analysis(output_directory, transactions, number_of_words, support_values, pattern_counts)
    number_of_images = length(transactions)
    saturated_images = count(transaction -> length(transaction) == number_of_words, transactions)
    saturation_fraction = saturated_images / number_of_images
    average_words = sum(length, transactions) / number_of_images
    analysis_path = joinpath(output_directory, "analysis.md")
    open(analysis_path, "w") do output_file
        println(output_file, "# Visual Pattern Mining Analysis")
        println(output_file, "")
        println(output_file, "Images and transactions: $(number_of_images).")
        println(output_file, "")
        for index in eachindex(support_values)
            println(output_file, "- Minsup $(support_values[index]): $(pattern_counts[index]) frequent itemsets.")
        end
        println(output_file, "")
        println(output_file, "Images containing all $(number_of_words) visual words: $(saturated_images)/$(number_of_images) ($(round(100 * saturation_fraction; digits = 2))%).")
        println(output_file, "Average visual words per image: $(round(average_words; digits = 2)).")
        println(output_file, "High saturation can reduce the ability of patterns to distinguish images. Compare a larger K or fewer descriptors on the same images.")
        println(output_file, "Each pattern can be used as a binary feature for classification or image retrieval. Evaluate on an independent test set before drawing conclusions.")
        println(output_file, "")
        println(output_file, "ORB describes local image regions. Visual words are descriptor clusters, not necessarily specific flower parts.")
        println(output_file, "Transactions discard spatial positions and repetitions. K, seed and image size affect results; co-occurrence does not establish classification performance.")
    end
end

# Chạy từ ảnh gốc đến giao dịch, tập phổ biến, biểu đồ và ảnh minh họa.
function run_visual_pipeline(image_directory, output_directory; maximum_images = 0, number_of_words = 8,
                             maximum_side = 256, maximum_descriptors = 100, random_seed = 42,
                             support_values = [0.7, 0.8, 0.9], archive_checksum = "")
    if maximum_images < 0 || number_of_words < 1 || maximum_side < 1 || maximum_descriptors < 1
        throw(ArgumentError("Image count, visual word count and dimensions must be valid."))
    end
    if isempty(support_values)
        throw(ArgumentError("At least one minimum support is required."))
    end
    for minimum_support in support_values
        if !isfinite(minimum_support) || minimum_support <= 0 || minimum_support > 1
            throw(ArgumentError("Minimum support must be greater than 0 and at most 1."))
        end
    end
    mkpath(output_directory)
    image_paths = find_flower_images(image_directory; maximum_images = maximum_images)
    transactions, records, training_count = prepare_visual_transactions(
        image_paths, image_directory, output_directory; maximum_side = maximum_side,
        maximum_descriptors = maximum_descriptors, number_of_words = number_of_words, random_seed = random_seed)
    run_rows = Tuple{Float64, Int, Int, Int, Float64, String}[]
    pattern_counts = Int[]
    all_itemsets = MiningResult()
    for minimum_support in support_values
        elapsed_time = @elapsed itemsets = mine_visual_transactions(transactions, minimum_support; implementation = :optimized)
        absolute_support = calculate_minimum_support_count(minimum_support, length(transactions))
        save_visual_itemsets(joinpath(output_directory, "itemsets_$(minimum_support).csv"), itemsets, length(transactions))
        write_itemsets(joinpath(output_directory, "itemsets_$(minimum_support).txt"), itemsets)
        push!(pattern_counts, length(itemsets))
        push!(run_rows, (minimum_support, absolute_support, length(transactions), length(itemsets), elapsed_time, "optimized"))
        merge!(all_itemsets, itemsets)
        println("Minsup $(minimum_support): $(length(itemsets)) frequent itemsets")
    end
    save_csv(joinpath(output_directory, "runs.csv"), ["minimum_support", "absolute_minimum_support",
             "num_transactions", "num_patterns", "seconds", "implementation"], run_rows)
    save_visual_figures(output_directory, transactions, support_values, pattern_counts)
    save_pattern_examples(output_directory, image_directory, transactions, records, all_itemsets)
    save_visual_analysis(output_directory, transactions, number_of_words, support_values, pattern_counts)
    number_of_valid_images = 0
    number_of_descriptors = 0
    number_of_empty_transactions = 0
    for record in records
        if record.status != "unreadable"
            number_of_valid_images += 1
        end
        number_of_descriptors += record.num_descriptors
    end
    for transaction in transactions
        if isempty(transaction)
            number_of_empty_transactions += 1
        end
    end
    dataset_url = ""
    if !isempty(archive_checksum)
        dataset_url = FLOWERS_DATASET_URL
    end
    summary = Dict("images" => length(records), "valid_images" => number_of_valid_images,
                   "empty_transactions" => number_of_empty_transactions, "total_descriptors" => number_of_descriptors,
                   "saturated_images" => count(transaction -> length(transaction) == number_of_words, transactions),
                   "training_descriptors" => training_count, "visual_words" => number_of_words,
                   "descriptor" => "ORB (ImageFeatures.jl)", "clustering" => "K-Means (Clustering.jl)",
                   "seed" => random_seed, "maximum_side" => maximum_side,
                   "maximum_descriptors" => maximum_descriptors, "archive_sha256" => archive_checksum,
                   "dataset_url" => dataset_url, "julia_version" => string(VERSION),
                   "run_utc" => string(Dates.now(Dates.UTC)))
    open(joinpath(output_directory, "dataset_summary.toml"), "w") do output_file
        TOML.print(output_file, summary)
    end
    return summary
end

# Đọc tham số, tải dữ liệu nếu cần và chạy ứng dụng ảnh.
function main_visual_pipeline(arguments)
    options = Dict("--images" => "", "--output" => "result/visual_patterns_julia",
                   "--limit" => "0", "--words" => "8", "--maximum-side" => "256",
                   "--maximum-descriptors" => "100", "--seed" => "42", "--minsup" => "0.7,0.8,0.9")
    if isodd(length(arguments))
        error("Each option requires a value.")
    end
    for index in 1:2:length(arguments)
        option = arguments[index]
        if !haskey(options, option)
            error("Unknown option: $(option)")
        end
        options[option] = arguments[index + 1]
    end
    image_directory = options["--images"]
    archive_checksum = ""
    if isempty(image_directory)
        image_directory, archive_checksum = download_flower_images(joinpath("data", "raw", "flowers"))
    end
    support_values = Float64[]
    for support_text in split(options["--minsup"], ',')
        push!(support_values, parse(Float64, support_text))
    end
    return run_visual_pipeline(image_directory, options["--output"];
        maximum_images = parse(Int, options["--limit"]), number_of_words = parse(Int, options["--words"]),
        maximum_side = parse(Int, options["--maximum-side"]), maximum_descriptors = parse(Int, options["--maximum-descriptors"]),
        random_seed = parse(Int, options["--seed"]), support_values = support_values, archive_checksum = archive_checksum)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_visual_pipeline(ARGS)
end
