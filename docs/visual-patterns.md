# Visual Pattern Mining bằng Julia

Ứng dụng tải ảnh Oxford Flowers-17, trích đặc trưng cục bộ ORB, tạo visual word bằng K-Means rồi chạy Apriori-TID của nhóm. Nhãn hoa không được đưa vào giao dịch. Bộ ảnh được tải từ [Oxford VGG](https://www.robots.ox.ac.uk/~vgg/data/flowers/17/index.html).

Phần ảnh dùng các gói Julia trong môi trường riêng `visual_environment`; môi trường Julia của thuật toán lõi không thay đổi. ORB là đặc trưng nhị phân; các giá trị 0 và 1 được đưa vào K-Means để tạo codebook. Cách này khác với SIFT và MiniBatchKMeans của bản Python cũ, nên không dùng kết quả cũ để báo cáo thay cho lần chạy Julia.

## Cài đặt và chạy

Bộ kết quả local đi kèm dùng Julia 1.13.4. Từ thư mục gốc dự án, cài các gói Julia cần thiết:

```powershell
julia --project=visual_environment -e 'using Pkg; Pkg.instantiate()'
```

Chạy thử trên 20 ảnh đầu tiên:

```powershell
julia --project=visual_environment scripts/visual_pipeline.jl --limit 20 --output result/visual_demo_julia
```

Chạy toàn bộ bộ ảnh (dùng thư mục mới để giữ kết quả lịch sử):

```powershell
julia --project=visual_environment scripts/visual_pipeline.jl --output result/visual_patterns_new
```

Chương trình tự tải bộ ảnh Oxford nếu chưa có, sau đó giải nén bằng `tar`. Dùng `--images duong_dan` nếu đã có thư mục ảnh. Các tham số có thể thay đổi gồm `--limit`, `--words`, `--maximum-side`, `--maximum-descriptors`, `--seed` và `--minsup` (ví dụ `--minsup 0.7,0.8,0.9`). Thư mục output cùng tên sẽ được ghi lại.

Kết quả nằm trong thư mục output: `flowers_spmf.txt`, `image_transaction_mapping.csv`, `codebook.csv`, `dataset_summary.toml`, `runs.csv`, các file `itemsets_*.csv`, `pattern_examples.csv` và `figures/`. Biểu đồ và hình minh họa được ghi bằng SVG và mở được bằng trình duyệt. Codebook được đọc lại sau khi lưu; các mức support trong cùng lần chạy dùng chung codebook và giao dịch.

Để kiểm thử:

```powershell
julia --project=. tests/runtests.jl
julia --project=visual_environment tests/test_visual_images.jl
```

[Notebook demo thống nhất](../notebooks/demo.ipynb) dùng kernel Python để gọi script Julia. Có cả Groceries và Flowers-17, chạy cấu hình K=8 và K=16; đã kiểm tra Run All từ kernel sạch local; bằng chứng Colab được lưu riêng trong `result/final/colab/`. Các thư mục kết quả từ pipeline Python cũ không nằm trong bản tích hợp; kết quả Julia trước sửa được giữ tại `result/visual_patterns_julia`.

## Cách tính support

Mỗi ảnh tương ứng đúng một giao dịch, gồm các mã visual word dương không trùng. Ảnh lỗi hoặc không có đặc trưng tạo một dòng rỗng và vẫn được giữ trong mapping và mẫu số support. Reader SPMF chung không chấp nhận dòng rỗng, vì vậy `read_visual_transactions` đọc định dạng này riêng; `mine_visual_transactions` tính `ceil(minsup × tổng số ảnh)` rồi gọi Apriori-TID của nhóm trên các giao dịch không rỗng. Support của từng tập không bị thay đổi.

Khi chọn ảnh minh họa, chương trình đếm lại các giao dịch chứa itemset và kiểm tra số ảnh đúng bằng support do thuật toán trả về. Visual word là cụm đặc trưng, không tự bảo đảm mang ý nghĩa của một bộ phận hoa. Việc biến ảnh thành tập làm mất vị trí và số lần lặp của đặc trưng; kết quả phụ thuộc lựa chọn descriptor, K và seed. Đồng xuất hiện không chứng minh khả năng phân loại.

## So sánh cấu hình

```powershell
julia --project=visual_environment scripts/visual_pipeline.jl --words 8 --maximum-descriptors 100 --output result/flowers_k8
julia --project=visual_environment scripts/visual_pipeline.jl --words 16 --maximum-descriptors 40 --output result/flowers_k16
```

So sánh tỷ lệ `saturated_images / images`, độ dài giao dịch và số tập phổ biến trong `runs.csv`. Kết quả local đi kèm:

| Cấu hình | Ảnh đọc | Không descriptor | Chứa đủ K word | Độ dài trung bình | Itemsets 0,7 / 0,8 / 0,9 |
|---|---:|---:|---:|---:|---:|
| K=8, tối đa 100 descriptors | 1.360 | 2 | 1.064 | 7,569 | 255 / 237 / 47 |
| K=16, tối đa 40 descriptors | 1.360 | 2 | 2 | 11,286 | 12 / 0 / 0 |

Seed 42, cùng archive Flowers-17; SHA-256 `fe38a60f8b4a95e657551247d3e7d799a3fafcdbc595be504b12839967823d70`. Mỗi cấu hình dùng 18.815 descriptor huấn luyện. Lần chạy dùng `--images data/raw/flowers/jpg`, nên trường URL/archive trong summary pipeline để trống; nguồn gốc archive được ghi tại metadata thực nghiệm. Tổng descriptor gán là 122.744 và 52.459.

[K=8](../result/final/flowers_k8/dataset_summary.toml) · [K=16](../result/final/flowers_k16/dataset_summary.toml). Script [verify_visual_results.jl](../scripts/verify_visual_results.jl) đã đếm lại support của toàn bộ 539 dòng kết quả K=8 và 12 dòng K=16 từ giao dịch, đồng thời đối chiếu Basic ở cả ba minsup. Mẫu số luôn là 1.360, gồm hai giao dịch rỗng.

K=8 bão hòa ở 78,24% ảnh; mẫu phổ biến có thể phản ánh codebook nhỏ thay vì bộ phận hoa có ý nghĩa. K=16 chỉ có 12 singleton đạt 70%, không có cặp/triple để minh họa; 80% và 90% không có tập đạt ngưỡng. Hai tham số K và giới hạn descriptor cùng đổi, vì vậy đây là so sánh cấu hình, chưa tách riêng tác động của K. Không so sánh ID visual word giữa codebook khác nhau.

Hình K=8 minh họa `(2, 3)` có support 1.277/1.360 đã đếm lại trực tiếp. Seed không bảo đảm codebook giống bit-for-bit giữa phiên bản Julia/BLAS hay nền tảng.


## Kiểm chứng Colab riêng

Demo chạy đủ 1.360 ảnh trên Julia 1.12.6/Linux, cùng archive, seed và cấu hình. K=8 thu 255/250/47 itemsets với 1.077 ảnh bão hòa; K=16 thu 11/0/0 với 8 ảnh bão hòa. Cả hai vẫn có hai giao dịch rỗng. Đã đếm lại toàn bộ support và so Basic thành công. Mã nguồn và các manifest trong lượt này có hash khớp local. [Metadata](../result/final/colab/verification.json) · [Notebook đã chạy](../result/final/colab/demo-executed.ipynb).

Bảng/hình trong [nguồn báo cáo](Report.pdf) sử dụng lượt local Julia 1.13.4, tách riêng kết quả Colab. Môi trường Julia/BLAS khác nhau có thể thay đổi nghiệm K-Means dù seed cố định; cần so codebook và giao dịch của từng lượt trước khi giải thích visual word.
