# Apriori-TID Mining

Project 02 — Khai phá dữ liệu, Nhóm 17, Trường Đại học Khoa học Tự nhiên, ĐHQG-HCM.

| Thành viên | MSSV |
|---|---|
| Võ Tấn An | 24127318 |
| Trịnh Tấn Phát | 24127485 |

Dự án cài đặt Apriori-TID bằng Julia với hai phiên bản `basic` và `optimized`. SPMF được dùng làm tham chiếu để đối chiếu từng frequent itemset và support count. Hai ứng dụng dùng chung thuật toán của nhóm: phân tích giỏ hàng Groceries và khai thác visual words từ Oxford Flowers-17.

## Nội dung

- [Báo cáo](docs/Report.pdf)
- [Kết quả thực nghiệm](docs/results.md)
- [Hướng dẫn tái lập và bằng chứng kiểm thử](docs/reproducibility.md)
- [Notebook demo](notebooks/demo.ipynb)
- [Kiến trúc](docs/architecture.md) và [API](docs/api_contract.md)

## Môi trường

Cần Julia 1.9 trở lên. Đối chiếu SPMF cần **Java 25 trở lên** vì JAR đi kèm được biên dịch cho Java 25. Peak RSS được đo trên Linux/macOS; người dùng Windows có thể chạy phần này qua WSL hoặc Colab.

Chạy các lệnh tại thư mục gốc của dự án:

```bash
julia --version
java -version
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=evaluation_environment -e 'using Pkg; Pkg.instantiate()'
julia --project=visual_environment -e 'using Pkg; Pkg.instantiate()'
```

Môi trường lõi chứa thuật toán và CLI. `evaluation_environment` bổ sung tải dữ liệu/vẽ biểu đồ; `visual_environment` chứa thư viện đọc ảnh, ORB và K-Means. Chi tiết vai trò thư viện ở [docs/REVIEW.md](docs/REVIEW.md).

## Chạy thuật toán

```bash
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt --implementation optimized --output result/optimized_output.txt
```

| Tham số | Ý nghĩa |
|---|---|
| Đường dẫn positional | File giao dịch đầu vào; có thể thay bằng `--input` |
| `--minsup` | Support tương đối trong khoảng `(0, 1]` |
| `--implementation` | `basic` (mặc định) hoặc `optimized` |
| `--output` | File kết quả; mặc định `result/output.txt` |

File đầu vào có một giao dịch mỗi dòng, các item là số nguyên dương cách nhau bằng khoảng trắng. Trong mỗi giao dịch, item được chuẩn hóa thành tập có thứ tự. Giao dịch trùng nhau vẫn được giữ và đóng góp riêng vào support.

```text
1 2 3
1 2
1 3
```

Output `1 2 #SUP: 2` nghĩa là tập `{1, 2}` xuất hiện trong hai giao dịch. Dùng `julia --project=. demo.jl --help` để xem trợ giúp CLI.

## Kiểm thử và đối chiếu SPMF

```bash
julia --project=. tests/runtests.jl
julia --project=. scripts/compare_spmf.jl tools/spmf.jar data/toy/sample.txt 0.6
```

Điểm chạy đầy đủ kiểm tra core, CLI, SPMF, luật kết hợp, giao dịch ảnh và tích hợp ảnh. Khi đạt, chương trình in `Full test suite completed successfully.` và thoát với mã 0. Ca kiểm thử ảnh hỏng có thể in lỗi JPEG; kết luận kiểm thử dựa trên test summary và mã thoát. `--core-only` chỉ chạy phần lõi.

Bộ bằng chứng lưu sẵn có **168/168 kiểm tra thuộc 16 testset** đạt trên local và Colab: [log local](result/correctness/final-tests.txt), [log Colab](result/final/colab/full-tests.txt).

## Dữ liệu

| Dataset | Mục đích | Nguồn |
|---|---|---|
| `data/toy/sample.txt` | Chạy thử nhanh | Kèm dự án |
| Chess, Mushroom, Retail, T10I4D100K | Benchmark | [FIMI](https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data/) |
| Groceries | Luật kết hợp | [arules](https://github.com/mhahsler/arules/tree/master/data_src/Groceries) |
| Oxford Flowers-17 | Visual pattern mining | [Oxford VGG](https://www.robots.ox.ac.uk/~vgg/data/flowers/17/index.html) |

Script tải lưu dữ liệu tại `data/raw/`, thư mục được bỏ qua bởi Git. Bốn benchmark có SHA-256 của file chuẩn hóa trong [datasets.csv](result/final/benchmark/datasets.csv). Retail và T10I4D100K dịch toàn bộ item ID lên một đơn vị để loại mã 0; quan hệ xuất hiện không đổi.

## Benchmark

```bash
julia --project=evaluation_environment scripts/fetch_datasets.jl benchmark
julia --threads=1 --project=. scripts/capture_run_metadata.jl result/benchmark_run
julia --startup-file=no --threads=1 --project=. scripts/run_benchmark.jl data/raw/benchmark result/benchmark_run/benchmark
julia --project=evaluation_environment scripts/plot_results.jl benchmark result/benchmark_run/benchmark
```

[configs/benchmark.toml](configs/benchmark.toml) quy định năm minsup mỗi dataset, warm-up, ba lượt đo, seed và dữ liệu tổng hợp. Pipeline xuất correctness, runtime, số itemset, peak RSS, scalability Retail 10–100% và ảnh hưởng độ dài giao dịch.

Để lặp Retail 100% trong ba tiến trình mới:

```bash
julia --startup-file=no --threads=1 --project=. scripts/measure_retail_processes.jl data/raw/benchmark/retail.txt result/benchmark_run/benchmark/retail_process_trials.csv
```

[Bộ kết quả tham chiếu](result/final/README.md) có đủ 20 cấu hình khớp từng itemset/support với SPMF. Runtime Julia là median của `mine()` sau warm-up; SPMF dùng thời gian nội bộ do JVM báo. Peak RSS bao gồm toàn bộ tiến trình Julia. Đọc [phạm vi đo và giới hạn](docs/results.md) khi so sánh các giá trị.

## Groceries

```bash
julia --project=evaluation_environment scripts/fetch_datasets.jl groceries
julia --project=. scripts/run_market_basket.jl data/raw/groceries/Groceries.data data/raw/groceries/Groceries.labels result/groceries_run 0.01 0.4 optimized
julia --project=evaluation_environment scripts/plot_results.jl groceries result/groceries_run
```

Hai ngưỡng lần lượt là minsup 1% và minconf 40%. Output gồm mapping, transactions, frequent itemsets, luật và top 10 theo lift. Trên 9.835 giỏ và 169 danh mục, cấu hình này cho 333 itemsets và 62 luật. [Phân tích chỉ số và ý nghĩa kinh doanh](docs/results.md#groceries).

## Flowers-17

```bash
julia --project=visual_environment scripts/visual_pipeline.jl --words 8 --maximum-descriptors 100 --seed 42 --minsup 0.7,0.8,0.9 --output result/flowers_k8_run
julia --project=visual_environment scripts/visual_pipeline.jl --words 16 --maximum-descriptors 40 --seed 42 --minsup 0.7,0.8,0.9 --output result/flowers_k16_run
```

Pipeline tự tải ảnh nếu chưa có, trích ORB descriptors, tạo codebook K-Means và chuyển mỗi ảnh thành một transaction. Có thể thêm `--limit 20` để chạy thử hoặc `--images <thư_mục>` để dùng ảnh đã giải nén. Ảnh không có descriptor vẫn được giữ trong mẫu số support.

```bash
julia --project=. scripts/verify_visual_results.jl result/flowers_k8_run
```

Lệnh kiểm tra đếm lại support từ giao dịch và đối chiếu Basic. [Hướng dẫn, kết quả và giới hạn biểu diễn ảnh](docs/visual-patterns.md).

## Notebook và Colab

- [Demo chung](notebooks/demo.ipynb): thiết lập môi trường, test, bốn ca correctness, benchmark và hai ứng dụng.
- [Demo benchmark/Groceries](notebooks/phat_demo.ipynb): ví dụ thuật toán, kết quả benchmark và luật kết hợp.
- [Mở nhánh main trên Colab](https://colab.research.google.com/github/torusama/apriori-tid-mining/blob/main/notebooks/demo.ipynb). Link dùng mã của nhánh đang công bố; khi dùng một bản sao local, cần cung cấp source cùng phiên bản cho runtime.

Mặc định `run_full_benchmark = False` hiển thị số đo lưu sẵn từ máy Mac. Đặt `True` để đo trên runtime đang chạy. Bốn ca đối chiếu nhanh và hai ứng dụng luôn được thực thi. [Notebook có output](result/final/colab/demo-executed.ipynb) và [log 10/10 cell](result/final/colab/run-all.txt) là bằng chứng lượt Colab riêng; thông tin nguồn/môi trường được giữ trong metadata.

## Báo cáo
- [docs/Report.pdf](docs/Report.pdf)
- [Overleaf source code](https://www.overleaf.com/project/6b0597a68fc2d2db841ba4bc/share#1b99371ae9a10fbc01a5af92194ec576e0330a52c31bd9bc)

## Cấu trúc

```text
src/                      Thuật toán, ứng dụng và công cụ đánh giá
scripts/                  CLI tải dữ liệu, benchmark, kiểm tra và vẽ
configs/                  Cấu hình benchmark
data/toy/                 Dữ liệu mẫu
tests/                   Điểm chạy, bộ kiểm thử và fixtures
evaluation_environment/   Dependencies tải dữ liệu và biểu đồ
visual_environment/       Dependencies ORB và K-Means
notebooks/                Notebook demo
result/final/             CSV, hình và bằng chứng thực nghiệm
docs/Report.pdf           Báo cáo
tools/spmf.jar            Công cụ tham chiếu SPMF
```
