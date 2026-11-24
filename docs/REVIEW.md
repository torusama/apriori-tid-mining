# Kiểm chứng cài đặt

## Thư viện và vai trò

| Phần | Thư viện/công cụ | Vai trò |
|---|---|---|
| Apriori-TID, CLI | Julia Base | Tự sinh ứng viên, đếm support, pruning và đọc/ghi |
| Kiểm thử | Test | Assertions và testsets |
| Benchmark | Random, SHA, Statistics, TOML | Seed, checksum, cấu hình và thống kê |
| Tải dữ liệu | Downloads, CodecZlib | Tải file và đọc gzip |
| Biểu đồ | CSV, Plots | Đọc bảng và vẽ |
| Xử lý ảnh | FileIO, ImageIO, ImageTransformations, ImageFeatures | Đọc ảnh, resize và ORB |
| Codebook | Clustering, Random, DelimitedFiles | K-Means, seed và lưu tâm cụm |
| Tham chiếu | Java, SPMF | Đối chiếu độc lập |
| Notebook | Python standard library, IPython.display | Gọi script Julia và hiển thị |
| Đóng gói báo cáo | Python standard library | Dựng bảng và ZIP LaTeX |

Core không gọi thư viện frequent itemset mining có sẵn. SPMF chỉ tham gia đối chiếu và benchmark. Các môi trường evaluation/visual tách dependencies hỗ trợ khỏi thuật toán lõi.

## Phạm vi kiểm thử

Điểm vào `tests/runtests.jl` chạy kiểm tra thuật toán, SPMF I/O, CLI, input validation, association rules, xử lý transaction ảnh rỗng và descriptor/codebook. Các ca biên gồm giao dịch trùng, tập rỗng ở đầu ra, itemset dài, minsup đúng/ngay trên ngưỡng và đường dẫn có dấu. Test ảnh có fixture JPEG hỏng để kiểm tra cách xử lý lỗi.

Bộ bằng chứng local và Colab đều đạt **168/168 kiểm tra trong 16 testset**. Log thực thi và môi trường được dẫn tại [reproducibility.md](reproducibility.md). `--core-only` không bao gồm toàn bộ tích hợp SPMF và ảnh.

Đối chiếu benchmark kiểm tra cả itemsets thiếu, thừa và sai count, không chỉ số lượng đầu ra. Groceries còn được đếm lại từ giao dịch để xác minh chỉ số của 62 luật. Kết quả ảnh được đếm lại trực tiếp và đối chiếu Basic ở ba minsup.

## Quy ước và giới hạn

- `Itemset = Tuple{Vararg{Int}}` hỗ trợ nhiều độ dài nhưng không phải kiểu cụ thể. Vòng đếm Optimized dùng vector ID nguyên; không khẳng định toàn bộ pipeline đã loại chi phí dispatch/cấp phát.
- Luật được sinh từ frequent union `X ∪ Y`, vì vậy cả union và antecedent đều đạt minsup. Sau đó lọc minconf; đây là quy ước association rule dùng trong dự án.
- Peak RSS cần Linux/macOS. Runtime Julia và thời gian nội bộ SPMF có phạm vi khác nhau.
- Dải minsup, workload và một máy đo không đại diện mọi môi trường; một số điểm có dao động. [Phân tích kết quả](results.md) ghi rõ phạm vi suy luận.
- Visual words là cụm descriptor, không tự mang ý nghĩa một bộ phận hoa; giao dịch bỏ vị trí và số lần lặp. [Tài liệu ảnh](visual-patterns.md) mô tả mức bão hòa và thay đổi codebook giữa môi trường.
