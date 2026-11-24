# Tái lập thực nghiệm

## Môi trường và dữ liệu

Thuật toán lõi dùng Julia; các dependencies bổ trợ được khóa bằng Project/Manifest của `evaluation_environment` và `visual_environment`. Java 25+ chạy JAR SPMF đi kèm. [Kiến trúc](architecture.md) mô tả ranh giới module; [API](api_contract.md) quy định dữ liệu chung.

| Lượt thực thi | Julia | Java | Nền tảng | Phạm vi |
|---|---|---|---|---|
| Benchmark lưu sẵn | 1.13.4, một thread | OpenJDK 27 | Apple M5, RAM 16 GiB, macOS aarch64 | 20 cấu hình, peak RSS, scalability, transaction width |
| Colab demo | 1.12.6 | OpenJDK 25.0.2 | Linux, CPU Standard | Full test, bốn ca correctness, Groceries, Flowers-17 |

Nguồn dataset được dẫn trong README. Lệnh tải kiểm tra SHA-256 bản benchmark chuẩn hóa; checksum được ghi trong [datasets.csv](../result/final/benchmark/datasets.csv). Retail và T10I4D100K dịch ID lên một đơn vị để giữ quy ước item dương. Archive Flowers-17 có SHA-256 `fe38a60f8b4a95e657551247d3e7d799a3fafcdbc595be504b12839967823d70`.

## Trình tự chạy

1. Instantiate ba môi trường và chạy `julia --project=. tests/runtests.jl`.
2. Tải bốn dataset bằng `scripts/fetch_datasets.jl benchmark`.
3. Chụp metadata trước khi đo bằng `scripts/capture_run_metadata.jl`.
4. Chạy `scripts/run_benchmark.jl` rồi `scripts/measure_retail_processes.jl` vào thư mục output mới.
5. Vẽ kết quả bằng `scripts/plot_results.jl` trong môi trường evaluation.
6. Chạy Groceries ở minsup 1%, minconf 40%; chạy Flowers-17 với K=8/100 và K=16/40, seed 42, minsup 0,7/0,8/0,9.
7. Kiểm tra support ảnh bằng `scripts/verify_visual_results.jl`; các lệnh đầy đủ nằm trong [README](../README.md).

Dùng thư mục output mới để giữ dữ liệu tham chiếu. Benchmark Julia đo median của ba lượt `mine()` sau warm-up. SPMF báo thời gian nội bộ JVM, còn peak RSS bao gồm cả tiến trình Julia; không đồng nhất ba phạm vi này. Cấu hình nằm ở [benchmark.toml](../configs/benchmark.toml).

## Bằng chứng đã lưu

| Hạng mục | Kết quả | Bằng chứng |
|---|---|---|
| Full test local | 168/168, 16 testset, exit 0 | [final-tests.txt](../result/correctness/final-tests.txt) |
| Full test Colab | 168/168, 16 testset, exit 0 | [full-tests.txt](../result/final/colab/full-tests.txt) |
| Benchmark | 20 cấu hình khớp từng itemset và support với SPMF | [benchmarks.csv](../result/final/benchmark/benchmarks.csv) |
| Groceries | 333 itemsets, 62 luật; kiểm tra lại toàn bộ chỉ số | [rule_verification.json](../result/final/market_basket/rule_verification.json) |
| Flowers local | Support của 539 + 12 dòng itemset được đếm lại và so Basic | [K8](../result/final/flowers_k8/verification.toml), [K16](../result/final/flowers_k16/verification.toml) |
| Notebook Colab | 10/10 cell có output, không có output lỗi | [notebook](../result/final/colab/demo-executed.ipynb), [log](../result/final/colab/run-all.txt) |

Lượt Colab được chạy từ base checkout kèm source upload. Hash nguồn và môi trường được lưu trong [verification.json](../result/final/colab/verification.json); kết quả này không chứng minh một commit công bố khác cũng đã chạy. CLI không ghi execution count vào notebook output; log tuần tự và output từng cell được dùng để xác nhận lượt thực thi.

## Đọc metadata

[run_manifest.toml](../result/final/run_manifest.toml) là snapshot trước khi đo, giữ ref và hash các file tại thời điểm đó. Việc cập nhật tên tác giả, tài liệu hay bố cục hình không thay đổi CSV thực nghiệm đã lưu.

Bảng/hình báo cáo sử dụng bộ kết quả local trong `result/final/`. K-Means có thể tạo codebook khác khi thay đổi Julia/BLAS dù dùng cùng seed; output Colab được giữ riêng. Giới hạn phép đo nằm trong [results.md](results.md), còn cách tính mẫu số ảnh và độ bão hòa ở [visual-patterns.md](visual-patterns.md).
