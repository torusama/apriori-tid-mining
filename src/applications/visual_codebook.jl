using Clustering
using Random
using DelimitedFiles

# Huấn luyện K-Means từ các đặc trưng đã chọn với seed cố định.
function fit_visual_codebook(descriptors::Matrix{Float32}, number_of_words::Int, random_seed::Int)
    if number_of_words < 1 || number_of_words > size(descriptors, 2)
        throw(ArgumentError("The number of visual words must be between 1 and the number of training descriptors."))
    end
    random_generator = MersenneTwister(random_seed)
    result = kmeans(descriptors, number_of_words; rng = random_generator, maxiter = 100)
    return result.centers
end

# Lưu các tâm cụm để có thể đọc lại mà không cần huấn luyện lại.
function save_visual_codebook(file_path::AbstractString, centers::AbstractMatrix)
    open(file_path, "w") do output_file
        writedlm(output_file, centers, ',')
    end
end

# Đọc lại các tâm cụm đã lưu trong file CSV.
function load_visual_codebook(file_path::AbstractString)
    return readdlm(file_path, ',', Float32)
end

# Gán từng đặc trưng vào tâm gần nhất và giữ mỗi mã visual word một lần.
function descriptors_to_visual_transaction(descriptors::AbstractMatrix, centers::AbstractMatrix)
    visual_words = Set{Int}()
    for descriptor_index in axes(descriptors, 2)
        nearest_word = 0
        nearest_distance = Inf
        for word_index in axes(centers, 2)
            distance = 0.0
            for position in axes(descriptors, 1)
                difference = descriptors[position, descriptor_index] - centers[position, word_index]
                distance += difference * difference
            end
            if distance < nearest_distance
                nearest_distance = distance
                nearest_word = word_index
            end
        end
        push!(visual_words, nearest_word)
    end
    return sort!(collect(visual_words))
end
