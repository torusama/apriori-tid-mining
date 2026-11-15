# Apriori-TID Mining

Đồ án khai thác tập mục phổ biến (frequent itemsets) bằng thuật toán **Apriori-TID**, viết bằng Julia. Chương trình đọc dữ liệu giao dịch, tìm các tập mục đạt ngưỡng support và ghi kết quả theo định dạng SPMF.

## Tình trạng triển khai

- **TASK 00:** Kiểu dữ liệu, kiểm tra đầu vào và giao diện chung đã triển khai.
- **TASK 01:** Apriori-TID cơ bản và đọc/ghi dữ liệu đã triển khai.
- **TASK 02:** Có bộ kiểm thử và công cụ đối chiếu với SPMF. Kiểm thử tích hợp SPMF cần cài thêm Java và có file `spmf.jar`.
- **TASK 03:** Phiên bản tối ưu chưa triển khai; chọn `optimized` sẽ báo lỗi.
- Các phần benchmark và ứng dụng trong cấu trúc dự án hiện vẫn là khung cho các bước tiếp theo.

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
| `--implementation` | Phiên bản thuật toán. Mặc định là `basic`; `optimized` chưa triển khai. | Không |

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
- **`Optimized Apriori-TID has not been implemented yet`:** dùng `--implementation basic` hoặc bỏ tham số này.
- **SPMF integration tests skipped:** cài Java, kiểm tra `java -version` và đặt `SPMF_JAR` trỏ đến file JAR hợp lệ.
