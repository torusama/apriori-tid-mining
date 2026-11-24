# Visual Pattern Mining bằng Julia

Ứng dụng tải ảnh Oxford Flowers-17, trích đặc trưng cục bộ ORB, tạo visual word bằng K-Means rồi chạy Apriori-TID của nhóm. Nhãn hoa không được đưa vào giao dịch. Bộ ảnh được tải từ [Oxford VGG](https://www.robots.ox.ac.uk/~vgg/data/flowers/17/index.html).

Phần ảnh dùng các gói Julia trong môi trường riêng `visual_environment`; môi trường Julia của thuật toán lõi không thay đổi. ORB là đặc trưng nhị phân; các giá trị 0 và 1 được đưa vào K-Means để tạo codebook. Cách này khác với SIFT và MiniBatchKMeans của bản Python cũ, nên không dùng kết quả cũ để báo cáo thay cho lần chạy Julia.

## Cài đặt và chạy

Đã chạy thử với Julia 1.10.10. Từ thư mục gốc dự án, cài các gói Julia cần thiết:

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
julia --project=. test/runtests.jl
julia --project=visual_environment tests/test_visual_images.jl
```

[Notebook demo thống nhất](../notebooks/demo.ipynb) dùng kernel Python để gọi script Julia. Có cả Groceries và Flowers-17, chạy cấu hình K=8 và K=16; chưa kiểm tra Run All trên Colab. Các thư mục kết quả từ pipeline Python cũ không nằm trong bản tích hợp; kết quả Julia trước sửa được giữ tại `result/visual_patterns_julia`.

## Cách tính support

Mỗi ảnh tương ứng đúng một giao dịch, gồm các mã visual word dương không trùng. Ảnh lỗi hoặc không có đặc trưng tạo một dòng rỗng và vẫn được giữ trong mapping và mẫu số support. Reader SPMF chung không chấp nhận dòng rỗng, vì vậy `read_visual_transactions` đọc định dạng này riêng; `mine_visual_transactions` tính `ceil(minsup × tổng số ảnh)` rồi gọi Apriori-TID của nhóm trên các giao dịch không rỗng. Support của từng tập không bị thay đổi.

Khi chọn ảnh minh họa, chương trình đếm lại các giao dịch chứa itemset và kiểm tra số ảnh đúng bằng support do thuật toán trả về. Visual word là cụm đặc trưng, không tự bảo đảm mang ý nghĩa của một bộ phận hoa. Việc biến ảnh thành tập làm mất vị trí và số lần lặp của đặc trưng; kết quả phụ thuộc lựa chọn descriptor, K và seed. Đồng xuất hiện không chứng minh khả năng phân loại.

Các gói Julia xử lý ảnh và gom cụm cần được nhóm xác nhận theo quy định của giảng viên.

## So sánh cấu hình

```powershell
julia --project=visual_environment scripts/visual_pipeline.jl --words 8 --maximum-descriptors 100 --output result/flowers_k8
julia --project=visual_environment scripts/visual_pipeline.jl --words 16 --maximum-descriptors 40 --output result/flowers_k16
```

So sánh tỷ lệ `saturated_images / images`, độ dài giao dịch và số tập phổ biến trong `runs.csv`. Bản ghi lịch sử K=8 có 1.066/1.360 ảnh chứa đủ 8 word; cấu hình mới chưa có số liệu thực nghiệm.
