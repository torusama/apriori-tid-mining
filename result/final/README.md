# Bộ kết quả thực nghiệm

| Thư mục/file | Nội dung |
|---|---|
| `benchmark/` | 60 dòng Basic/Optimized/SPMF trên 20 cấu hình; peak RSS, Retail scaling, transaction width, ba tiến trình Retail và biểu đồ |
| `market_basket/` | 9.835 giỏ, mapping, 333 itemsets, 62 luật, top 10; đối chiếu SPMF và kiểm tra lại chỉ số |
| `flowers_k8/`, `flowers_k16/` | Kết quả local Julia 1.13.4 trên 1.360 ảnh; support được đếm lại và so Basic |
| `colab/` | Notebook có output, log Run All 10/10 cell, full test exit 0 và output ứng dụng trên Julia 1.12.6/Linux |
| `run_manifest.toml` | Snapshot phiên bản nguồn, cấu hình và hash trước khi đo |

Runtime/RAM trong `benchmark/` thuộc máy Mac được mô tả ở `environment.txt`, không phải số đo Colab. Các môi trường có thể tạo codebook ảnh khác nhau dù cùng seed; output Colab được giữ riêng.

Các thư mục kết quả khác ngoài `result/final/` là các lượt thực nghiệm khác, không dùng để thay số liệu của bộ này. Dữ liệu thô được tải lại từ nguồn theo README; checksum chuẩn hóa và cấu hình được giữ để tái lập.

[Phân tích kết quả](../../docs/results.md) · [Hướng dẫn tái lập](../../docs/reproducibility.md) · [Báo cáo](../../docs/Report.pdf).
