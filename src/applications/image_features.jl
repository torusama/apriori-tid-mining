using Downloads
using SHA
using FileIO
using ImageIO
using ImageTransformations
using ImageFeatures

const FLOWERS_DATASET_URL = "https://www.robots.ox.ac.uk/~vgg/data/flowers/17/17flowers.tgz"
const VISUAL_DESCRIPTOR_LENGTH = 256

# Tải bộ ảnh Oxford Flowers-17 và ghi nhận mã kiểm tra của file tải về.
function download_flower_images(destination::AbstractString)
    mkpath(destination)
    archive_path = joinpath(destination, "17flowers.tgz")
    if !isfile(archive_path)
        temporary_path = archive_path * ".download"
        try
            Downloads.download(FLOWERS_DATASET_URL, temporary_path; timeout = 300)
            mv(temporary_path, archive_path; force = true)
        finally
            if isfile(temporary_path)
                rm(temporary_path)
            end
        end
    end
    archive_checksum = bytes2hex(open(SHA.sha256, archive_path))
    image_directory = joinpath(destination, "jpg")
    if !isdir(image_directory)
        run(`tar -xzf $archive_path -C $destination`)
    end
    image_paths = find_flower_images(image_directory)
    if length(image_paths) != 1360
        throw(ArgumentError("Oxford Flowers-17 must contain exactly 1,360 images."))
    end
    return image_directory, archive_checksum
end

# Tìm ảnh trong thư mục theo thứ tự ổn định và kiểm tra tên ảnh không trùng.
function find_flower_images(image_directory::AbstractString; maximum_images::Int = 0)
    image_paths = String[]
    image_names = Set{String}()
    for (directory, _, file_names) in walkdir(image_directory)
        for file_name in file_names
            extension = lowercase(splitext(file_name)[2])
            if extension in (".jpg", ".jpeg", ".png")
                if file_name in image_names
                    throw(ArgumentError("Duplicate image filename: $(file_name)"))
                end
                push!(image_names, file_name)
                push!(image_paths, joinpath(directory, file_name))
            end
        end
    end
    sort!(image_paths)
    if isempty(image_paths)
        throw(ArgumentError("No images found in $(image_directory)."))
    end
    if maximum_images > 0 && maximum_images < length(image_paths)
        return image_paths[1:maximum_images]
    end
    return image_paths
end

# Đọc ảnh, giữ tỉ lệ khi thu nhỏ và trích xuất đặc trưng ORB cục bộ.
function extract_image_descriptors(image_path::AbstractString, maximum_side::Int, maximum_descriptors::Int)
    image = try
        load(image_path)
    catch error
        details = (status = "unreadable", height = 0, width = 0, message = sprint(showerror, error))
        return zeros(Float32, VISUAL_DESCRIPTOR_LENGTH, 0), details
    end
    height, width = size(image)
    scale = min(1.0, maximum_side / max(height, width))
    if scale < 1.0
        new_height = max(1, round(Int, height * scale))
        new_width = max(1, round(Int, width * scale))
        image = imresize(image, (new_height, new_width))
    end
    gray_image = ImageFeatures.Gray.(image)
    parameters = ORB(num_keypoints = maximum_descriptors)
    descriptors, _, _ = create_descriptor(gray_image, parameters)
    descriptor_matrix = zeros(Float32, VISUAL_DESCRIPTOR_LENGTH, length(descriptors))
    for descriptor_index in eachindex(descriptors)
        descriptor = descriptors[descriptor_index]
        if length(descriptor) != VISUAL_DESCRIPTOR_LENGTH
            throw(ArgumentError("Invalid ORB descriptor length: $(image_path)"))
        end
        for position in eachindex(descriptor)
            descriptor_matrix[position, descriptor_index] = Float32(descriptor[position])
        end
    end
    status = "ok"
    if isempty(descriptors)
        status = "no_descriptors"
    end
    details = (status = status, height = height, width = width, message = "")
    return descriptor_matrix, details
end
