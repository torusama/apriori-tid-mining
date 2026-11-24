## Báo cáo — kết quả lịch sử trước chỉnh sửa

Các số liệu dưới đây được giữ nguyên từ lần chạy trước. Cần chạy lại benchmark và kiểm thử trên code mới trước khi dùng làm bằng chứng nộp bài.

## Chương 1 · Apriori-TID tối ưu

Bản cơ bản duyệt toàn bộ ứng viên cho mỗi bản ghi TID và dựng lại hai tập sinh của từng ứng viên. Nếu cấp `k` có `C[k]` ứng viên và cấp trước còn `R[k−1]` bản ghi, vòng đếm cơ bản xét `R[k−1] × C[k]` cặp bản ghi–ứng viên. Bản tối ưu tính hai tập sinh một lần mỗi cấp, dùng ID số và lập chỉ mục ứng viên theo tập sinh thứ nhất. Mỗi bản ghi chỉ duyệt các nhóm ứng viên của những tập nó chứa. Mảng đánh dấu dùng chỉ số bản ghi để tra tập sinh còn lại. Sau khi đếm support, bản tối ưu giữ các tập đủ ngưỡng trong bản ghi trung gian.

Hai bản dùng chung bước sinh và cắt tỉa ứng viên, quy tắc ngưỡng `ceil(minsup × số giao dịch)` và kiểu kết quả `MiningResult`. Kiểm thử bao gồm giao dịch lặp, support đúng ngưỡng, tập kết quả rỗng, tập mục dài, CLI và các ca đối chiếu SPMF. [Thuật toán tối ưu](../src/algorithm/apriori_tid_optimized.jl) · [Output kiểm thử](../result/correctness/phat-tests.txt)

## Chương 2 · Thực nghiệm

Bốn dataset đến từ FIMI. Retail do Tom Brijs cung cấp. Retail và T10I4D100K có mã 0 trong nguồn nên toàn bộ mã của từng dataset được dịch lên một đơn vị. Cả Julia và SPMF nhận dữ liệu đã chuẩn hóa giống nhau. Bảng correctness đếm support theo giao dịch, so khớp từng itemset và ghi riêng số itemset thiếu, thừa và sai support. [Nguồn FIMI](https://www.cs.rpi.edu/~zaki/Workshops/FIMI/data/) · [Thông tin dataset và checksum](../result/benchmark/datasets.csv)

Phép đo dùng máy Apple M5 16 GiB, Julia 1.13.4 một thread, OpenJDK 27 và SPMF Apriori TID FAST v2.66. Runtime Julia là median của ba lần gọi `mine()` sau warm-up. Runtime SPMF là median thời gian nội bộ do ba lượt SPMF báo cáo. Hai cột runtime sử dụng phạm vi đo riêng. Peak RSS đo bằng tiến trình Julia mới ở ngưỡng giữa và bao gồm khởi động, đọc dữ liệu và ghi kết quả. Cấp phát tích lũy trong runtime được ghi riêng theo byte. [Số liệu](../result/benchmark/benchmarks.csv) · [Môi trường](../result/benchmark/environment.txt)

Cả hai bản Julia khớp **100% itemset và support count với SPMF ở cả 20 cấu hình dataset–minsup**. Bảng sau ghi thời gian và peak RSS tại ngưỡng giữa của mỗi dataset. [Biểu đồ runtime](../result/benchmark/runtime_ms.png) · [Biểu đồ peak RSS](../result/benchmark/peak_ram.png)

Ở T10I4D100K với minsup 3,5%, API trước chỉnh sửa tính ngưỡng 3.501 do làm tròn số thực nhị phân. Ghi chú của lần chạy trước cho biết kiểm tra thêm với ngưỡng chính xác 3.500 cho cùng 40 itemset và support count. Bản chỉnh sửa chuyển tỷ lệ sang phân số chính xác và có test hồi quy mới; chưa chạy lại thực nghiệm.

| Dataset | Minsup giữa | Basic (ms) | Optimized (ms) | SPMF (ms) | Peak RSS basic → optimized (MiB) |
|---|---:|---:|---:|---:|---:|
| Chess | 92% | 680,7 | 31,6 | 24 | 303,3 → 285,4 |
| Mushroom | 55% | 257,6 | 19,4 | 14 | 303,2 → 282,0 |
| Retail | 3% | 1.561,5 | 49,8 | 182 | 491,0 → 306,1 |
| T10I4D100K | 4% | 8.683,2 | 51,1 | 56 | 394,5 → 284,5 |

- **Ảnh hưởng của minsup.** Từ ngưỡng cao nhất xuống thấp nhất trong mỗi dải, số tập phổ biến tăng từ 44 lên 1.195 ở Chess và từ 31 lên 1.189 ở Mushroom. Retail tăng từ 16 lên 84 và T10I4D100K từ 17 lên 40. Retail và T10I4D100K vẫn có chi phí lớn ở bản cơ bản vì thuật toán duyệt tập ứng viên theo số lượng lớn giao dịch, kể cả khi các ứng viên ít đồng xuất hiện. [Biểu đồ số tập mục](../result/benchmark/itemsets.png)
- **Mức cải thiện.** Qua 20 cấu hình, runtime Julia của bản tối ưu nhanh hơn bản cơ bản từ 8,7× đến 331×. Ở ngưỡng giữa, peak RSS giảm 6–38%. SPMF có thời gian báo cáo thấp hơn bản tối ưu ở ngưỡng giữa của hai bộ dữ liệu dày. Kết quả ở các ngưỡng thưa cần đọc cùng phạm vi đo và phiên bản SPMF.
- **Scalability của Retail.** Với minsup 3% và seed 42, khi dữ liệu tăng từ 8.816 lên 88.162 giao dịch, median của bản cơ bản tăng từ 150,0 lên 2.266,7 ms và bản tối ưu từ 4,8 lên 137,4 ms. Mức tăng toàn dải lớn hơn hệ số tăng số dòng. Cùng tập đầy đủ, runtime optimized ở phép đo riêng theo minsup là 49,8 ms. Cần lặp lại phép đo giữa các tiến trình trước khi suy ra tốc độ tăng ổn định. [Số liệu scalability](../result/benchmark/scalability.csv)
- **Độ dài giao dịch.** Với 3.000 giao dịch, 32 item, minsup 35% và seed 42, số tập phổ biến là 0, 32, 32, 528 ở độ dài 8, 12, 16, 20. Từ độ dài 16 lên 20, nhiều cặp vượt ngưỡng và kích hoạt thêm một cấp sinh ứng viên. Runtime basic tăng từ khoảng 369 lên 4.045 ms. Optimized tăng từ 14,3 lên 154,8 ms. [Số liệu độ dài](../result/benchmark/transaction_width.csv) · [Biểu đồ hai phép đo](../result/benchmark/scaling_and_width.png)

### Hướng cải tiến tiếp theo

1. **Nhóm tập mục theo prefix khi sinh ứng viên.** Bộ sinh hiện xét từng cặp tập phổ biến trước khi kiểm tra prefix. Sắp xếp và ghép các tập trong từng nhóm prefix để giảm số phép so sánh, rồi đo lại thời gian sinh ứng viên theo cấp.
2. **Chọn biểu diễn TID theo mật độ.** Thử bitset cho những tập có nhiều TID và danh sách TID đã sắp xếp cho những tập thưa. Dùng cùng dữ liệu và ngưỡng để đo chi phí giao, bộ nhớ và tính tương đương với bản hiện tại.

## Chương 3 · Groceries

Ma trận arules có 9.835 giao dịch và 169 nhóm sản phẩm. Số lượng dương biểu thị sản phẩm có trong giỏ. Mỗi giỏ trung bình có 4,41 nhóm sản phẩm, trải từ 1 đến 32. Có 2.824 giỏ có cùng tập nhóm sản phẩm với một dòng trước đó. Mỗi dòng vẫn đóng góp một giao dịch vào support. [Tài liệu arules](https://michael.hahsler.net/arules/reference/Groceries.html) · [Phân phối độ dài giỏ](../result/market_basket/basket_lengths.png)

Ở minconf 40%, độ nhạy theo minsup như sau. Mức 1% yêu cầu ít nhất 99 giỏ chứa hợp hai vế và cho đủ luật để xếp hạng. Bản cơ bản, bản tối ưu và SPMF khớp cả 333 itemset và support count ở mức này.

| Minsup | Frequent itemsets | Luật đạt minconf |
|---:|---:|---:|
| 0,50% | 1.001 | 270 |
| 0,75% | 531 | 119 |
| **1,00%** | **333** | **62** |
| 1,50% | 180 | 25 |
| 2,00% | 122 | 15 |

- **Lift cao nhất.** `citrus fruit + root vegetables → other vegetables` có 102 giỏ, support 1,04%, confidence 58,62% và lift 3,03. Có thể dùng luật để chọn nhóm nhận gợi ý rau khi đã có trái cây họ cam quýt và rau củ.
- **Phủ nhiều giỏ hơn.** `root vegetables + whole milk → other vegetables` có 228 giỏ, support 2,32%, confidence 47,40% và lift 2,45. Có thể thử gợi ý mua kèm cho nhóm này để có lượng quan sát lớn hơn.
- **Thiên lệch danh mục.** Cả mười luật đầu đều hướng đến `other vegetables`. Nên thử gợi ý ở nhóm giỏ chưa có danh mục đích rồi theo dõi tỷ lệ mua kèm, biên lợi nhuận và độ ổn định theo kỳ. Dữ liệu chỉ phản ánh một cửa hàng trong 30 ngày.

[Bảng top 10](../result/market_basket/top10_rules.csv) · [Biểu đồ lift](../result/market_basket/top10_rules.png) · [Toàn bộ luật](../result/market_basket/rules.csv)
