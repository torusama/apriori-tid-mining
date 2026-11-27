# Apriori-TID Mining

Nhóm 17, Project 02 — Khai thác dữ liệu và ứng dụng - 24KHMT1, Trường Đại học Khoa học Tự nhiên, ĐHQG-HCM.

| Thành viên | MSSV |
|---|---|
| Võ Tấn An | 24127318 |
| Trịnh Tấn Phát | 24127485 |

Dự án cài đặt thuật toán khai thác tập phổ biến **Apriori-TID** bằng Julia dựa trên bài báo [Fast Algorithms for Mining Association Rules](https://www.vldb.org/conf/1994/P487.PDF). Hai phiên bản `basic` và `optimized` dùng chung bước sinh ứng viên và được đối chiếu từng itemset, support count với [SPMF](https://www.philippe-fournier-viger.com/spmf/AprioriTID.php). Bản tối ưu dùng ID nguyên, chỉ mục theo tập sinh và mảng đánh dấu để giảm công việc đếm trong các bản ghi trung gian.

- [Báo cáo PDF](docs/Report.pdf): cài đặt, thí nghiệm, phân tích và hai ứng dụng.
- [Mở notebook demo trên Google Colab](https://colab.research.google.com/github/torusama/apriori-tid-mining/blob/main/notebooks/demo_colab.ipynb) · [Notebook trong repo](notebooks/demo_colab.ipynb).

## Cài đặt

Cần Julia 1.9 trở lên; Java 25 trở lên để chạy SPMF và bộ test đầy đủ. Đo peak RAM trên Linux cần GNU `time` tại `/usr/bin/time` (Ubuntu/Debian: `sudo apt-get install time`); notebook Colab tự cài nếu thiếu. Môi trường có internet khi cài dependencies và tải dữ liệu. Các lệnh dưới đây chạy tại thư mục gốc repository:

```bash
julia --version
java -version
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=evaluation_environment -e 'using Pkg; Pkg.instantiate()'
julia --project=visual_environment -e 'using Pkg; Pkg.instantiate()'
```

Môi trường gốc chứa thuật toán, CLI và test; `evaluation_environment` dùng để tải dữ liệu và vẽ biểu đồ; `visual_environment` chứa các thư viện ảnh, ORB và K-Means. File `tools/spmf.jar` là chương trình tham chiếu, không dùng để tạo kết quả của hai ứng dụng.

<details>
<summary>macOS/Homebrew: cấu hình thư viện cho GR/FFMPEG</summary>

Nếu Julia từ Homebrew báo thiếu `libssl.3.dylib` hoặc xung đột zlib khi vẽ hình, cài OpenSSL 3 và khởi chạy Jupyter với đường dẫn thư viện sau:

```bash
brew install openssl@3
DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix openssl@3)/lib:/usr/lib" jupyter lab notebooks/demo_local.ipynb
```

Lượt Run All local trên macOS được kiểm tra với cấu hình thư viện này. Colab không cần thiết lập biến này.

</details>

## Chạy khai thác

```bash
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt --implementation optimized --output result/optimized.txt
julia --project=. demo.jl --help
```

`--minsup` là support tương đối trong khoảng `(0, 1]`; ngưỡng count là `ceil(minsup × số giao dịch)`. `--implementation` chọn `basic` (mặc định) hoặc `optimized`; `--output` mặc định là `result/output.txt`. Đường dẫn đầu vào có thể truyền trực tiếp hoặc dùng `--input`.

Đầu vào SPMF có một giao dịch trên mỗi dòng, item là số nguyên dương cách nhau bằng dấu cách. Item trùng trong cùng giao dịch được chuẩn hóa; các giao dịch trùng nhau vẫn được tính riêng. Ví dụ:

```text
1 2 3
1 2
1 3
```

Output `1 2 #SUP: 2` cho biết `{1, 2}` xuất hiện trong hai giao dịch.

## Kiểm thử

```bash
julia --project=. test/runtests.jl
julia --project=. scripts/compare_spmf.jl tools/spmf.jar data/toy/sample.txt 0.6
```

Bộ đầy đủ kiểm tra thuật toán, biên support, I/O, CLI, SPMF, luật kết hợp và xử lý ảnh. Các test ảnh cần `visual_environment` đã được cài đặt. `julia --project=. test/runtests.jl --core-only` chỉ chạy phần lõi và không thay thế bộ đầy đủ.

Kết quả lần chạy đầy đủ trên Windows, Julia 1.10.10 và Java 25, ngày 25/11/2026:

```text
Test Summary:              | Pass  Total
TASK 02 - SPMF integration |   19     19
Test Summary:                         | Pass  Total
Image descriptors and visual codebook |    7      7
Full test suite completed successfully.
```

Tổng cộng **168/168** kiểm tra trong 16 testset đạt, mã thoát 0. Test cố ý đọc ảnh JPEG hỏng có thể in thông báo lỗi của các thư viện đọc ảnh dù test đạt.

### Kiểm thử bản hiện tại

Chạy trên mã nền `acd5a4b`, macOS, Julia 1.13.4 và OpenJDK 27 bằng:

```bash
julia --startup-file=no --threads=1 --project=. test/runtests.jl
```

<details>
<summary>Output: 168/168 kiểm tra, 16 testset, exit 0</summary>

```text
TASK 00 - Base functions |   19     19  2.2s
Exact minimum support boundary |    7      7  0.2s
TASK 01 - Candidate generation |    6      6  0.2s
TASK 01 - Intermediate transaction records |    9      9  0.2s
TASK 02 - Five toy databases |    7      7  0.2s
TASK 02 - VLDB 1994 Figure 3 |    1      1  0.0s
TASK 02 - Boundary cases |    3      3  0.0s
TASK 03 - Optimized Apriori-TID |   30     30  0.3s
Independent support counts |    6      6  0.2s
TASK 02 - SPMF file input and output |   11     11  0.3s
TASK 02 - Command line interface |   12     12  0.3s
TASK 02 - SPMF comparator |    6      6  0.2s
TASK 02 - SPMF integration |   19     19  2.7s
Groceries mapping and association-rule metrics |   15     15  1.0s
Visual patterns preserve empty image transactions |   10     10  0.2s
Image descriptors and visual codebook |    7      7  8.8s
Full test suite completed successfully.
Exit code: 0
```

</details>

## Dữ liệu

| Dataset | Công dụng | Nguồn công khai |
|---|---|---|
| `data/toy/sample.txt` | Ví dụ nhỏ | Có sẵn trong repo |
| Chess, Mushroom, Retail, T10I4D100K | Benchmark | [FIMI repository](https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data/) |
| Groceries | Phân tích giỏ hàng | [arules Groceries](https://github.com/mhahsler/arules/tree/master/data_src/Groceries) |
| Oxford Flowers-17 | Mẫu trực quan | [Oxford VGG](https://www.robots.ox.ac.uk/~vgg/data/flowers/17/) |

```bash
julia --project=evaluation_environment scripts/fetch_datasets.jl all
```

Script tải benchmark và Groceries vào `data/raw/`; Flowers-17 được pipeline ảnh tự tải. Benchmark được chuẩn hóa, kiểm tra kích thước và SHA-256 trong `scripts/fetch_datasets.jl`. Với Retail và T10I4D100K, ID được dịch một đơn vị khi dữ liệu chứa 0; quan hệ xuất hiện không đổi. `data/raw/` và output chạy mới không đưa vào Git.

Theo Q&A của TA, nhóm có thể tải benchmark trực tiếp từ FIMI. Notebook tự tải và kiểm tra checksum; Hugging Face/Kaggle là phương án lưu trữ dự phòng được khuyến khích để tăng độ sẵn sàng, không phải điều kiện bắt buộc theo phần giải đáp này.

## Thực nghiệm

```bash
julia --startup-file=no --threads=1 --project=. scripts/run_benchmark.jl data/raw/benchmark result/benchmark tools/spmf.jar configs/benchmark.toml
julia --project=evaluation_environment scripts/plot_results.jl benchmark result/benchmark
```

Cấu hình trong `configs/benchmark.toml` dùng năm mức minsup cho từng bộ, ba lượt đo, seed 42, các tập con Retail 10%, 25%, 50%, 75%, 100%, và dữ liệu tổng hợp có độ dài giao dịch thay đổi. Pipeline so sánh itemset/support, runtime, số itemset, peak RSS giữa Basic/Optimized, scalability và độ dài giao dịch. Peak RSS đo toàn tiến trình Julia; thời gian SPMF là thời gian nội bộ Java nên phạm vi đo khác thời gian hàm `mine()` của Julia.

Theo báo cáo, hai bản khớp SPMF ở **20/20 cấu hình** benchmark đã đo. Tại minsup giữa, Basic/Optimized đạt 6,57× trên Chess, 9,52× trên Mushroom, 13,11× trên Retail và 41,86× trên T10I4D100K ở môi trường được mô tả trong báo cáo. Peak RSS của Optimized tăng 1,41% trên Mushroom; kết quả phụ thuộc dữ liệu và môi trường. Bảng số liệu, biểu đồ, giới hạn phép đo và hai hướng cải tiến nằm trong [báo cáo](docs/Report.pdf).

## Ứng dụng 1: phân tích giỏ hàng

```bash
julia --project=evaluation_environment scripts/fetch_datasets.jl groceries
julia --project=. scripts/run_market_basket.jl data/raw/groceries/Groceries.data data/raw/groceries/Groceries.labels result/groceries 0.01 0.4 optimized
julia --project=evaluation_environment scripts/plot_results.jl groceries result/groceries
```

Pipeline chuyển Groceries thành giao dịch, khai thác frequent itemsets và sinh luật với minsup 1%, minconf 40%; output gồm mapping, itemsets, luật và top 10 theo lift. Báo cáo ghi nhận 333 itemsets và 62 luật trên 9.835 giỏ. Luật đồng xuất hiện là giả thuyết mua kèm, không tự chứng minh quan hệ nhân quả.

## Ứng dụng 2: khai thác mẫu trực quan

```bash
julia --project=visual_environment scripts/visual_pipeline.jl --words 8 --maximum-descriptors 100 --seed 42 --minsup 0.7,0.8,0.9 --output result/flowers_k8
julia --project=visual_environment scripts/visual_pipeline.jl --words 16 --maximum-descriptors 40 --seed 42 --minsup 0.7,0.8,0.9 --output result/flowers_k16
julia --project=. scripts/verify_visual_results.jl result/flowers_k8
```

Pipeline trích ORB descriptors, xây codebook bằng K-Means và chuyển mỗi ảnh thành một giao dịch visual words trước khi khai thác bằng Apriori-TID. Ảnh không có descriptor vẫn được tính trong mẫu số support. Thêm `--limit 20` để thử nhanh hoặc `--images <thư_mục>` để dùng ảnh đã có. Hai cấu hình thay đổi đồng thời số cụm và số descriptor, nên không tách riêng ảnh hưởng từng tham số.

## Notebook và tái lập

- [Bản local](notebooks/demo_local.ipynb): dùng checkout hiện có và Julia/Java đã cài đặt.
- [Bản Colab](notebooks/demo_colab.ipynb): tự chuẩn bị source và runtime trên Colab.
- Hai bản dùng chung các cell demo; khác nhau ở cell khởi tạo môi trường. Bản local dùng kernel Python 3 trong Jupyter/IPython và yêu cầu Julia/Java đã có trong PATH.


Notebook tự chuẩn bị Julia/Java khi cần trên Colab, cài môi trường, chạy bộ test, đối chiếu nhanh bốn benchmark và chạy cả hai ứng dụng. Lần đầu cài và precompile dependencies trên Colab CPU có thể mất hơn 10 phút; cần chờ cell khởi tạo hoàn tất trước khi chạy các cell sau. Mặc định `run_full_benchmark = True` tại mục 4.2 để chạy đầy đủ thí nghiệm và tạo biểu đồ; đặt `False` để bỏ qua bước này khi cần chạy nhanh. Các kết quả mới nằm trong workspace tạm được notebook in ra. Số đo trong báo cáo thuộc môi trường thực nghiệm được ghi trong báo cáo và không phải số đo Colab hiện tại. K-Means có thể tạo codebook khác giữa phiên bản Julia/BLAS; cần kiểm tra support trên transaction/codebook của từng lượt và không đối chiếu ID visual word giữa các codebook khác nhau.

## Cấu trúc

```text
src/                     Thuật toán, ứng dụng và đánh giá
scripts/                 CLI, tải dữ liệu, benchmark, vẽ và kiểm tra
configs/                 Cấu hình benchmark
notebooks/demo_colab.ipynb     Notebook demo Colab
notebooks/demo_local.ipynb     Notebook demo local
test/runtests.jl         Điểm chạy test đầy đủ
tests/                   Test và dữ liệu fixture
data/toy/                Dữ liệu ví dụ
evaluation_environment/ Môi trường tải dữ liệu và vẽ
visual_environment/     Môi trường xử lý ảnh
tools/spmf.jar           Cài đặt SPMF tham chiếu
docs/Report.pdf          Báo cáo
```
