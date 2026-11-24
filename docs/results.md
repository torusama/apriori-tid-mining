# Kết quả thực nghiệm

Bộ kết quả tham chiếu dùng cho báo cáo nằm trong [result/final](../result/final/). Các thư mục `result/benchmark` và `result/market_basket` là kết quả lịch sử. Phiên bản nguồn, fingerprint của mã đo, cấu hình, checksum và phạm vi đo được lưu trong [run_manifest.toml](../result/final/run_manifest.toml). Toàn bộ **168 kiểm tra thuộc 16 testset** hoàn thành với mã thoát 0, gồm SPMF và tích hợp ảnh: [log đầy đủ](../result/correctness/final-tests.txt).

## Cài đặt và tối ưu

Basic hiện đã tính trước hai tập sinh của ứng viên ở mỗi cấp. Với mỗi bản ghi TID, Basic vẫn duyệt danh sách ứng viên và kiểm tra hai tập sinh bằng tuple. Không dùng mô tả “tạo lại tập sinh ở mỗi bản ghi” cho bản tích hợp này.

Optimized gán ID nguyên cho itemset, nhóm ứng viên theo ID tập sinh thứ nhất và đánh dấu ID có mặt trong bản ghi bằng mảng dùng lại. Khi đếm support, mỗi bản ghi chỉ duyệt ứng viên liên quan đến các tập sinh nó chứa. Sau khi lọc support, bản ghi trung gian chỉ giữ ID của itemset phổ biến. Hai bản dùng chung candidate generation, pruning và ngưỡng count chính xác `ceil(minsup × N)`.

## Benchmark

Bốn dataset FIMI được chuẩn hóa và kiểm tra SHA-256. Retail và T10I4D100K dịch toàn bộ item ID lên một đơn vị để loại mã 0; phép đổi giữ nguyên quan hệ xuất hiện. [Dataset/checksum](../result/final/benchmark/datasets.csv) · [Cấu hình năm minsup](../configs/benchmark.toml)

Máy đo Apple M5, RAM 16 GiB, macOS aarch64, Julia 1.13.4 một thread, OpenJDK 27, SPMF Apriori TID FAST v2.66. Julia dùng median ba lần `mine()` sau warm-up; SPMF dùng median thời gian nội bộ của ba JVM mới. Hai phạm vi thời gian khác nhau nên chỉ so sánh mô tả. Peak RSS đo toàn bộ tiến trình Julia mới, gồm khởi động, đọc và ghi; khác với byte cấp phát tích lũy. [Môi trường](../result/final/benchmark/environment.txt) · [CSV thời gian](../result/final/benchmark/benchmarks.csv)

Cả Basic và Optimized khớp **100% từng itemset và support count với SPMF tại đủ 20 cấu hình**; không có itemset thiếu, thừa hay sai count. T10I4D100K tại 3,5% dùng đúng ngưỡng **3.500**, thu được 40 itemset. [Đối chiếu](../result/final/benchmark/benchmarks.csv)

| Dataset | Minsup giữa | Basic (ms) | Optimized (ms) | SPMF (ms) | Basic/Optimized | Peak RSS Basic → Optimized (MiB) |
|---|---:|---:|---:|---:|---:|---:|
| Chess | 92% | 340,2 | 51,8 | 22 | 6,57× | 310,9 → 291,6 |
| Mushroom | 55% | 326,0 | 34,3 | 25 | 9,52× | 283,8 → 287,8 |
| Retail | 3% | 1.326,8 | 101,2 | 393 | 13,11× | 380,4 → 299,9 |
| T10I4D100K | 4% | 3.235,2 | 77,3 | 252 | 41,86× | 356,6 → 286,9 |

Qua 20 cấu hình, hệ số Basic/Optimized nằm trong **3,19–70,87×**. Peak RSS giảm 6,22% ở Chess, 21,16% ở Retail và 19,54% ở T10I4D100K; riêng Mushroom **tăng 1,41%**. Mức cấp phát vòng đếm thấp hơn không bảo đảm toàn bộ peak RSS giảm, vì runtime và đọc/ghi cũng đóng góp vào tiến trình.

[Runtime, trục log](../result/final/benchmark/runtime_ms.png) · [Số itemset](../result/final/benchmark/itemsets.png) · [Peak RSS](../result/final/benchmark/peak_ram.png)

- **Minsup:** số tập phổ biến tăng 44 → 1.195 (Chess), 31 → 1.189 (Mushroom), 16 → 84 (Retail), 17 → 40 (T10I4D100K). Chi phí duyệt ứng viên còn phụ thuộc mật độ giao dịch và số bản ghi trung gian, không chỉ số itemset đầu ra.
- **Scalability:** Retail 10–100%, seed 42, minsup 3%, tăng từ 8.816 lên 88.162 giao dịch. Basic tăng 186,9 → 1.437,9 ms; Optimized 22,3 → 112,3 ms. Một số điểm không đơn điệu. Ba tiến trình mới tại 100% lần lượt cho Basic 1.031,6/1.051,4/1.044,0 ms và Optimized 77,5/151,6/78,5 ms. Đây là bằng chứng dao động giữa các lượt; chưa đủ để suy ra định luật tăng trưởng. [Scalability](../result/final/benchmark/scalability.csv) · [Ba tiến trình](../result/final/benchmark/retail_process_trials.csv)
- **Độ dài giao dịch:** 3.000 giao dịch tổng hợp, 32 item, seed 42, minsup 35%. Độ dài 8/12/16/20 cho 0/32/32/528 itemset. Từ độ dài 16 lên 20, Basic tăng 196,0 → 3.466,8 ms; Optimized 24,2 → 265,4 ms. Độ dài lớn làm nhiều cặp vượt ngưỡng và kích hoạt cấp sinh tiếp theo. [CSV](../result/final/benchmark/transaction_width.csv) · [Hình](../result/final/benchmark/scaling_and_width.png)

Máy đo còn chạy ứng dụng khác; chỉ dùng một máy, một seed và ba lượt cho mỗi điểm. Các con số mô tả lượt thực nghiệm đã lưu, chưa chứng minh ưu thế trên mọi workload hay môi trường.

### Hai cải tiến tiếp theo

1. **Ghép ứng viên theo nhóm prefix.** Hàm hiện xét từng cặp itemset đã sắp xếp trước khi kiểm tra prefix. Chỉ ghép trong cùng nhóm prefix để giảm cặp được xét; profiling riêng thời gian sinh ứng viên và kiểm tra output/support sau thay đổi.
2. **Biểu diễn theo mật độ.** Thử bitset cho tập ID dày và vector ID đã sắp xếp cho tập thưa. Tính cả chi phí chuyển đổi và bộ nhớ chỉ mục; đo từng cấp trên Chess/Mushroom và Retail trước khi chọn ngưỡng chuyển.

Có thể khảo sát tiếp việc giảm tuple/dictionary ở cấp sinh, sau khi profiling cho thấy phần này chiếm tỷ trọng đáng kể.

## Groceries

9.835 giỏ, 169 danh mục, trung bình 4,41 danh mục/giỏ (1–32). Có 2.824 giỏ trùng tập danh mục với dòng trước, vẫn giữ làm các giao dịch riêng. Minsup 1% tương ứng ít nhất 99 giỏ, minconf 40% tạo **333 itemset, 62 luật**. Basic, Optimized và SPMF khớp support của cả 333 itemset. [Summary](../result/final/market_basket/summary.toml) · [Đối chiếu](../result/final/market_basket/correctness.txt)

Với luật X → Y: support = count(X∪Y)/N; confidence = count(X∪Y)/count(X); lift = confidence/(count(Y)/N). Bộ chỉ số được kiểm tra lại từ giao dịch đã lưu.

- `citrus fruit + root vegetables → other vegetables`: 102 giỏ, support 1,04%, confidence 58,62%, lift 3,03. Có thể chọn nhóm nhận thử nghiệm gợi ý rau dựa trên giỏ hiện tại.
- `root vegetables + whole milk → other vegetables`: 228 giỏ, support 2,32%, confidence 47,40%, lift 2,45. Phủ nhiều giỏ hơn, phù hợp khảo sát một nhóm thử nghiệm lớn hơn.
- Top 10 đều có vế phải `other vegetables`. Điều này phản ánh cấu trúc danh mục và độ phổ biến của nhóm đích; cần xem thêm độ đa dạng, support và độ ổn định theo kỳ.

Dữ liệu một cửa hàng trong 30 ngày. Đồng xuất hiện không chứng minh tác động của khuyến mãi hay lợi nhuận. Có thể thử nghiệm gợi ý/khuyến mãi bằng nhóm đối chứng, đo tỷ lệ mua kèm, giá trị giỏ và biên lợi nhuận.

[Top 10 luật](../result/final/market_basket/top10_rules.csv) · [Biểu đồ lift](../result/final/market_basket/top10_rules.png) · [Độ dài giỏ](../result/final/market_basket/basket_lengths.png) · [Toàn bộ luật](../result/final/market_basket/rules.csv)

## Flowers-17 và báo cáo

Hai cấu hình ảnh đã chạy lại trên đủ 1.360 ảnh bằng Julia; xem [chi tiết và giới hạn](visual-patterns.md).
Nguồn báo cáo độc lập nằm trong [docs/Report.pdf](docs/Report.pdf)
