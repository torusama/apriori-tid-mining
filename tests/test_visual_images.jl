using Test
include(joinpath(@__DIR__, "..", "src", "applications", "image_features.jl"))
include(joinpath(@__DIR__, "..", "src", "applications", "visual_codebook.jl"))

@testset "Image descriptors and visual codebook" begin
    centers = Float32[0 10; 0 10]
    descriptors = Float32[0 0.1 10; 0 0.1 10]
    @test descriptors_to_visual_transaction(descriptors, centers) == [1, 2]
    @test isempty(descriptors_to_visual_transaction(zeros(Float32, 2, 0), centers))
    @test_throws ArgumentError fit_visual_codebook(descriptors, 4, 42)

    first_codebook = fit_visual_codebook(descriptors, 2, 42)
    second_codebook = fit_visual_codebook(descriptors, 2, 42)
    @test first_codebook == second_codebook

    mktempdir() do directory
        codebook_path = joinpath(directory, "codebook.csv")
        save_visual_codebook(codebook_path, first_codebook)
        @test load_visual_codebook(codebook_path) == first_codebook

        image_path = joinpath(directory, "broken.jpg")
        write(image_path, "not an image")
        broken_descriptors, details = extract_image_descriptors(image_path, 256, 100)
        @test details.status == "unreadable"
        @test size(broken_descriptors, 2) == 0
    end
end
