# Apriori-TID Mining

Đồ án cài đặt thuật toán **Apriori-TID bằng Julia** để tìm các tập mục phổ biến trong dữ liệu giao dịch. Project có hai phiên bản `basic` và `optimized`, được đối chiếu kết quả với SPMF.

Project gồm ba phần:

- **Thuật toán:** đọc giao dịch, tìm tập phổ biến và ghi kết quả theo định dạng SPMF.
- **Thực nghiệm:** so sánh kết quả và thời gian chạy với SPMF; đo RAM và khả năng mở rộng.
- **Ứng dụng:** tìm luật mua hàng từ Groceries và tìm mẫu trực quan từ ảnh Flowers-17.

## 1. Dữ liệu sử dụng

| Dữ liệu | Dùng để làm gì | Nguồn |
| --- | --- | --- |
| `data/toy/sample.txt` | Chạy thử nhanh thuật toán | Có sẵn trong project |
| Chess, Mushroom, Retail, T10I4D100K | Đánh giá và so sánh với SPMF | [FIMI](https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data/) |
| Groceries | Phân tích giỏ hàng, tìm luật kết hợp | [arules](https://github.com/mhahsler/arules/tree/master/data_src/Groceries) |
| Oxford Flowers-17 | Tìm mẫu trực quan trên ảnh | [Oxford VGG](https://www.robots.ox.ac.uk/~vgg/data/flowers/17/index.html) |

Dữ liệu tải về được lưu trong `data/raw/`. Thư mục này không được đưa lên Git; các lệnh bên dưới sẽ tự tải dữ liệu khi cần.

## 2. Cấu trúc project

```text
apriori-tid-mining/
├── demo.jl                  # Chạy thuật toán từ dòng lệnh
├── src/                     # Thuật toán, ứng dụng và công cụ đánh giá
├── scripts/                 # Các lệnh tải dữ liệu, chạy và vẽ kết quả
├── data/toy/                # Dữ liệu mẫu
├── test/runtests.jl         # Lệnh chạy toàn bộ kiểm thử
├── tests/                   # Các bài kiểm thử và dữ liệu kiểm thử
├── notebooks/demo.ipynb     # Notebook demo trên Google Colab
├── configs/                 # Cấu hình thực nghiệm
├── result/                  # Kết quả, bảng và biểu đồ
├── tools/spmf.jar           # SPMF dùng để so sánh
├── docs/                    # Tài liệu project
├── Project.toml             # Môi trường Julia cho thuật toán
├── evaluation_environment/  # Môi trường tải dữ liệu và vẽ biểu đồ
└── visual_environment/      # Môi trường xử lý ảnh
```

## 3. Cài đặt

Cần [Julia 1.9 trở lên](https://julialang.org/downloads/). Để chạy toàn bộ test hoặc so sánh với SPMF, cài thêm Java 25 trở lên; file `tools/spmf.jar` đã có trong repo.

Mở terminal tại thư mục gốc của project (thư mục chứa `Project.toml`). Các lệnh sau dùng PowerShell trên Windows:

```powershell
julia --version
java -version
```

Cài các thư viện cần cho tải dữ liệu, vẽ biểu đồ và xử lý ảnh. Chỉ cần cài một lần:

```powershell
julia --project=evaluation_environment -e "using Pkg; Pkg.instantiate()"
julia --project=visual_environment -e "using Pkg; Pkg.instantiate()"
```

## 4. Chạy thuật toán

Chạy bản cơ bản trên dữ liệu mẫu với minsup 60%:

```powershell
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt
```

Kết quả được ghi vào `result/output.txt`. Để chạy bản tối ưu và chọn file đầu ra:

```powershell
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt --implementation optimized --output result/optimized_output.txt
```

Ý nghĩa các tham số:

| Tham số | Ý nghĩa |
| --- | --- |
| `data/toy/sample.txt` | Đường dẫn file giao dịch đầu vào |
| `--minsup 0.6` | Ngưỡng support 60%; nhập số lớn hơn 0 và không quá 1 |
| `--implementation` | Chọn `basic` hoặc `optimized`; mặc định là `basic` |
| `--output` | Đường dẫn file kết quả; mặc định là `result/output.txt` |

File đầu vào gồm một giao dịch trên mỗi dòng, các item là số nguyên dương cách nhau bằng dấu cách:

```text
1 2 3
1 2
1 3
```

Trong file kết quả, `1 2 #SUP: 2` nghĩa là tập `{1, 2}` xuất hiện trong 2 giao dịch.

## 5. Kiểm thử

Sau khi cài Java và môi trường ảnh ở mục 3, chạy:

```powershell
julia --project=. test/runtests.jl
```

Lệnh này kiểm tra thuật toán, đọc/ghi file, dòng lệnh, ứng dụng, và đối chiếu với SPMF trên dữ liệu kiểm thử. Khi chạy xong, chương trình in `Full test suite completed successfully.`. Test ảnh cố tình đọc một file ảnh hỏng nên có thể in thông báo lỗi JPEG.

Lần kiểm tra ngày 24/11/2026 trên Julia 1.10.10 và Java 25: **toàn bộ test pass**, mã thoát `0`.

Để lưu output của lần kiểm thử mới nhất:

```powershell
julia --project=. test/runtests.jl 2>&1 | Tee-Object -FilePath result/correctness/final-tests.txt
$LASTEXITCODE
```

`$LASTEXITCODE` bằng `0` khi lệnh chạy thành công. Có thể chạy riêng phần thuật toán bằng `julia --project=. test/runtests.jl --core-only`; lệnh này không chạy kiểm thử tích hợp SPMF và ảnh.

Để so sánh riêng hai phiên bản với SPMF trên dữ liệu mẫu:

```powershell
julia --project=. scripts/compare_spmf.jl tools/spmf.jar data/toy/sample.txt 0.6
```

## 6. Chạy ứng dụng giỏ hàng

Chạy lần lượt hai lệnh sau để tải Groceries và tạo luật kết hợp:

```powershell
julia --project=evaluation_environment scripts/fetch_datasets.jl groceries
julia --project=. scripts/run_market_basket.jl data/raw/groceries/Groceries.data data/raw/groceries/Groceries.labels result/market_basket_new 0.01 0.4
```

Ở lệnh thứ hai, `0.01` là minsup 1%, `0.4` là minconf 40%. Kết quả nằm trong `result/market_basket_new/`; xem `top10_rules.csv` để biết 10 luật có lift cao nhất.

Để vẽ biểu đồ từ kết quả vừa tạo:

```powershell
julia --project=evaluation_environment scripts/plot_results.jl groceries result/market_basket_new
```

## 7. Chạy ứng dụng ảnh

Lệnh sau tải Oxford Flowers-17 nếu chưa có, chuyển ảnh thành giao dịch visual words và chạy Apriori-TID:

```powershell
julia --project=visual_environment scripts/visual_pipeline.jl --output result/visual_patterns_new
```

Kết quả nằm trong `result/visual_patterns_new/`: `runs.csv` chứa số tập phổ biến, `itemsets_*.csv` chứa các tập tìm được và `figures/` chứa hình minh họa.

Muốn chạy thử nhanh trên 20 ảnh đầu tiên:

```powershell
julia --project=visual_environment scripts/visual_pipeline.jl --limit 20 --output result/visual_demo_new
```

Chi tiết về cách xử lý ảnh: [Visual Pattern Mining](docs/visual-patterns.md).

## 8. Chạy benchmark

Benchmark đầy đủ cần Linux/macOS để đo peak RAM; nếu dùng Windows, chạy bằng WSL hoặc Colab. Chạy từ thư mục gốc của project:

```bash
julia --project=evaluation_environment -e 'using Pkg; Pkg.instantiate()'
julia --project=evaluation_environment scripts/fetch_datasets.jl benchmark
julia --threads=1 --project=. scripts/run_benchmark.jl data/raw/benchmark result/benchmark_new
julia --project=evaluation_environment scripts/plot_results.jl benchmark result/benchmark_new
```

Các lệnh lần lượt cài thư viện, tải 4 dataset, chạy benchmark và vẽ biểu đồ. Kết quả mới nằm trong `result/benchmark_new/`; các ngưỡng và số lần đo được đặt trong [configs/benchmark.toml](configs/benchmark.toml).

Kết quả có sẵn trong `result/benchmark/` và `result/market_basket/` là kết quả của lần chạy trước. Cần chạy lại để đánh giá code hiện tại.

## 9. Google Colab

- Notebook: [notebooks/demo.ipynb](notebooks/demo.ipynb).
- [Mở trên Google Colab](https://colab.research.google.com/github/torusama/apriori-tid-mining/blob/main/notebooks/demo.ipynb). Link này cần file notebook được đưa lên nhánh `main`; chưa xác nhận Run All trên Colab.
- Notebook chạy test, kiểm tra nhanh 4 dataset và chạy hai ứng dụng. Đặt `run_full_benchmark = True` trong notebook để chạy benchmark đầy đủ; mặc định notebook hiển thị kết quả benchmark cũ.
