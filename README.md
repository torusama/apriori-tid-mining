# Apriori-TID Mining

Đồ án khai thác tập mục phổ biến (frequent itemsets) bằng thuật toán **Apriori-TID**, viết bằng Julia. Chương trình đọc dữ liệu giao dịch, tìm các tập mục đạt ngưỡng support và ghi kết quả theo định dạng SPMF.

## Tình trạng triển khai

- **TASK 00:** Kiểu dữ liệu, kiểm tra đầu vào và giao diện chung đã triển khai.
- **TASK 01:** Apriori-TID cơ bản và đọc/ghi dữ liệu đã triển khai.
- **TASK 02:** Có bộ kiểm thử và công cụ đối chiếu với SPMF. Kiểm thử tích hợp SPMF cần cài thêm Java và có file `spmf.jar`.
- **TASK 03:** Bản `optimized` dùng ID số và chỉ mục tập sinh trong các bản ghi Apriori-TID.
- **Benchmark và Groceries:** Có script chạy, CSV, biểu đồ và [notebook demo của Phát](notebooks/phat_demo.ipynb).

## Yêu cầu

- Julia phiên bản **1.9 trở lên** thuộc dòng 1.x. Đã chạy thử với Julia 1.10.10.
- Java và `spmf.jar` chỉ cần khi đối chiếu với SPMF.

Cài Julia theo hướng dẫn tại [trang chính thức](https://julialang.org/downloads/). Sau khi cài, mở lại terminal hoặc VS Code và kiểm tra:

```powershell
julia --version
```

Các lệnh bên dưới được chạy trong PowerShell, tại thư mục gốc `apriori-tid-mining` (thư mục chứa `Project.toml`). Nếu đang ở thư mục cha, chạy:

```powershell
cd apriori-tid-mining
```

Dự án hiện không khai báo thư viện ngoài cho chức năng cơ bản. Tùy chọn `--project=.` giúp Julia sử dụng môi trường của dự án.

## Chạy nhanh

```powershell
julia --project=. scripts/cli.jl --input data/toy/sample.txt --output result/basic_output.txt --minsup 0.6 --implementation basic
```

Kết quả hiển thị:

```text
Input transactions: 5
Frequent itemsets: 6
Output file: result/basic_output.txt
```

Mở `result/basic_output.txt` để xem các tập phổ biến. Thư mục đầu ra sẽ được tạo nếu chưa tồn tại; file đầu ra cùng tên sẽ bị ghi đè.

### Tham số dòng lệnh

| Tham số | Ý nghĩa | Bắt buộc |
| --- | --- | --- |
| `--input` | Đường dẫn file giao dịch đầu vào. | Có |
| `--output` | Đường dẫn file kết quả. | Có |
| `--minsup` | Minimum support dạng tỷ lệ, lớn hơn 0 và không quá 1. Ví dụ `0.6` là 60%. | Có |
| `--implementation` | Chọn `basic` (mặc định) hoặc `optimized`. | Không |

Các tham số được nhập theo cặp tên và giá trị. Đặt đường dẫn trong dấu ngoặc kép nếu đường dẫn có khoảng trắng.

Ngưỡng support count được tính bằng `ceil(minimum_support × số giao dịch)`. Ví dụ với 5 giao dịch và `--minsup 0.6`, một tập mục phải xuất hiện trong ít nhất 3 giao dịch để được giữ lại.

## Định dạng dữ liệu

File đầu vào là văn bản: mỗi dòng là một giao dịch, gồm các mã item là số nguyên dương, cách nhau bằng khoảng trắng. Ví dụ:

```text
1 2 3
1 2
1 3
2 3
1 2 3
```

Các item trùng trong cùng một giao dịch được loại bỏ và sắp xếp tăng dần; các giao dịch trùng nhau vẫn được tính riêng. Dòng bắt đầu bằng `#`, `%` hoặc `@` được xem là chú thích và bỏ qua. Dòng trống, item không hợp lệ hoặc dữ liệu không có giao dịch sẽ gây lỗi.

Kết quả có định dạng SPMF, mỗi dòng là một tập mục và số giao dịch chứa tập đó:

```text
1 2 #SUP: 3
```

Dòng trên nghĩa là tập `{1, 2}` xuất hiện trong 3 giao dịch. `#SUP` là số lần xuất hiện, không phải tỷ lệ phần trăm.

## Sử dụng từ Julia

Mở Julia trong thư mục dự án bằng `julia --project=.` rồi chạy:

```julia
using FrequentItemsetMining

transactions = read_transactions("data/toy/sample.txt")
result = mine(transactions; minimum_support=0.6, implementation=:basic)
println(result[(1, 2)])  # 3
write_itemsets("result/basic_output.txt", result)
```

Nếu tự tạo `transactions`, dùng `normalize_transactions` để chuẩn hóa trước khi gọi `mine`. Kết quả là một `Dict` ánh xạ tuple itemset sang support count. Xem thêm [API contract](docs/api_contract.md) và [kiến trúc](docs/architecture.md).

## Kiểm thử

Chạy bộ kiểm thử từ thư mục dự án:

```powershell
julia --project=. test/runtests.jl
```

Bộ test bao gồm kiểm tra dữ liệu, sinh ứng viên, kết quả trên dữ liệu mẫu, đọc/ghi, CLI và bộ so sánh SPMF. Nếu chưa cấu hình Java và `SPMF_JAR`, phần tích hợp SPMF sẽ được bỏ qua và có thông báo trong terminal.

### Đối chiếu với SPMF

Cài Java, chuẩn bị file `spmf.jar`, rồi kiểm tra Java đã có trong PATH:

```powershell
java -version
```

Để chạy cả phần tích hợp SPMF trong bộ kiểm thử, đặt biến môi trường trong terminal hiện tại (thay đường dẫn bằng vị trí file thực tế):

```powershell
$env:SPMF_JAR = "C:\path\to\spmf.jar"
julia --project=. test/runtests.jl
```

Có thể so sánh riêng một file hoặc chạy các bộ dữ liệu mẫu:

```powershell
julia --project=. scripts/compare_spmf.jl "C:\path\to\spmf.jar" data/toy/sample.txt 0.6
julia --project=. scripts/run_spmf_tests.jl "C:\path\to\spmf.jar"
```

Lệnh thứ hai ghi báo cáo vào `result/correctness/spmf_comparison.txt`. Kết quả khớp khi không có tập mục thiếu, tập mục thừa hoặc support count khác nhau.

## Tái lập benchmark và Groceries

Chạy các lệnh dưới đây từ thư mục gốc trên macOS hoặc Linux. Cần Julia, Python 3 và Java tương thích với JAR trong `tools/`. Matplotlib dùng để dựng hình từ các CSV đã tạo. Đợt bàn giao chạy với Julia 1.13.4, OpenJDK 27 và SPMF Apriori TID FAST v2.66.

```bash
python3 -m pip install matplotlib
python3 scripts/fetch_datasets.py all
julia --threads=1 --project=. scripts/run_benchmark.jl data/raw/benchmark result/benchmark
python3 scripts/plot_results.py benchmark result/benchmark
julia --project=. scripts/run_market_basket.jl data/raw/groceries/Groceries.data data/raw/groceries/Groceries.labels result/market_basket 0.01 0.4
python3 scripts/plot_results.py groceries result/market_basket
SPMF_JAR=tools/spmf.jar julia --project=. test/runtests.jl
```

- Benchmark lấy Chess, Mushroom, Retail và T10I4D100K từ [FIMI](https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data/). Bộ tải sắp xếp và loại item trùng trong từng giao dịch. Retail và T10I4D100K được cộng 1 vào mọi ID để đáp ứng hợp đồng mã item dương. [Cấu hình benchmark](configs/benchmark.toml) khai báo minsup, seed và số lượt đo. [Kết quả benchmark](result/benchmark/benchmarks.csv) lưu từng phép so sánh và [thông tin môi trường](result/benchmark/environment.txt) mô tả phạm vi đo.
- Groceries dùng ma trận và bảng nhãn từ arules. Các cột có số lượng dương được ghi nhận một lần trong từng giỏ. Bảng top 10 dùng minsup 1% và minconf 40%. [Nguồn arules](https://github.com/mhahsler/arules/tree/master/data_src/Groceries) · [Bảng top 10](result/market_basket/top10_rules.csv)
- Notebook chạy được từ repo local bằng kernel Python 3. Khi mở trên Colab, notebook dùng nhánh chứa các file bàn giao và tải Julia nếu cần. Link Colab công khai thuộc bước nộp bài của nhóm. [Kết quả kiểm thử](result/correctness/phat-tests.txt) · [Ghi chú cho báo cáo](docs/phat-results.md)

## Cấu trúc chính

```text
apriori-tid-mining/
├── Project.toml              # Khai báo dự án Julia
├── src/                      # Thuật toán, xử lý dữ liệu và so sánh SPMF
├── scripts/                  # CLI và các script chạy/đối chiếu
├── data/toy/                 # Dữ liệu ví dụ
├── test/runtests.jl          # Điểm chạy bộ kiểm thử
├── tests/                    # Test và dữ liệu kiểm thử
├── docs/                     # Kiến trúc và hợp đồng API
├── configs/                  # Tham số dự kiến dùng chung
└── result/                   # Kết quả được tạo khi chạy
```

## Xử lý lỗi thường gặp

- **`julia` không được nhận diện:** kiểm tra Julia đã cài và nằm trong PATH, sau đó mở lại terminal hoặc VS Code.
- **Không tìm thấy `Project.toml`, script hoặc file input:** chuyển terminal vào thư mục `apriori-tid-mining` trước khi chạy. Các đường dẫn tương đối trong ví dụ được tính từ thư mục này.
- **`Minimum support must be greater than 0 and at most 1`:** nhập tỷ lệ như `0.6`, không nhập `60`.
- **SPMF integration tests skipped:** cài Java, kiểm tra `java -version` và đặt `SPMF_JAR` trỏ đến file JAR hợp lệ.
