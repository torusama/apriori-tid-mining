# Rà soát mã nguồn theo đề Project 02

Bản này dựa trên `apriori-tid-mining-ready.zip` và đề `itemset.md` do nhóm cung cấp. Chưa phải kết quả nghiệm thu.

## Thư viện

| Phần | Thư viện | Vai trò |
|---|---|---|
| Core Apriori-TID, CLI | Julia Base | Tự sinh ứng viên, đếm support, lọc, đọc/ghi |
| Unit test | Test | Kiểm thử |
| Benchmark | Random, SHA, Statistics, TOML | Seed, checksum, thống kê, cấu hình |
| Tải và giải nén | Downloads, CodecZlib | Tải file và đọc gzip |
| Biểu đồ | CSV, Plots | Đọc bảng và vẽ |
| Ứng dụng ảnh | FileIO, ImageIO, ImageTransformations, ImageFeatures | Đọc ảnh, resize, trích ORB |
| Codebook | Clustering, Random, DelimitedFiles | K-Means, seed, lưu tâm cụm |
| Đối chiếu | Java, SPMF | Tham chiếu độc lập, không sinh kết quả ứng dụng |
| Colab | Python standard library, IPython.display | Điều phối lệnh Julia và hiển thị kết quả |

Đề giới hạn numpy/pandas/bitarray cho lựa chọn Python; không đặt danh sách gói tương tự cho Julia. Không thấy thư viện FIM bị cấm trong source lõi. Xác nhận phạm vi dùng thư viện ứng dụng nếu giảng viên có hướng dẫn thêm. Các gói trong Manifest có thể là phụ thuộc gián tiếp, không phải thư viện được gọi trực tiếp trong core.

## Sửa code

- `candidate_generation.jl`: ghép hai tuple cùng phần đầu, kiểm tra tập con; dùng chung hàm `generating_subsets` cho hai bản. Ví dụ (1,2,3) sinh từ (1,2) và (1,3).
- `apriori_tid.jl`: tách ba bước rõ ràng: cấp 1, đếm ứng viên từ bản ghi cấp trước, vòng lặp khai thác. Tính hai tập sinh một lần cho mỗi ứng viên, vẫn duyệt mọi ứng viên trong mỗi bản ghi.
- `apriori_tid_optimized.jl`: giữ ID số, chỉ mục tập sinh và mảng ghi dấu; không bỏ tối ưu để làm ngắn code. `@inbounds` dùng ở vòng lặp với ID sinh nội bộ. Không thêm `@simd` vào vòng cập nhật gián tiếp vì có phụ thuộc dữ liệu.
- `utils.jl` và `api.jl`: hai phiên bản kiểm tra đầu vào một lần trong hàm khai thác. Giữ phép đổi minsup chính xác ở biên. Bổ sung test kiểm tra đầu vào và support độc lập.
- `market_basket.jl`: đọc nhãn và tạo mapping bằng vòng lặp tường minh, đóng file bằng `open do`.
- `visual_pipeline.jl`: giải thích hai lượt trích descriptor để hạn chế RAM; dùng kiểu cụ thể cho các dòng kết quả đơn giản.
- `image_features.jl`: tải vào file tạm trước khi đổi tên, không giữ file đang tải dở nếu lỗi.
- Thông báo, lỗi, tên test, tiêu đề biểu đồ sinh mới và nội dung analysis.md sinh mới bằng tiếng Anh; chú thích mã tiếng Việt. Giữ tên file tiếng Việt trong test đường dẫn. README, markdown notebook và tài liệu báo cáo vẫn tiếng Việt. Không dịch hoặc sửa các kết quả lịch sử.

## Các điểm còn cần xác nhận

1. `Itemset = Tuple{Vararg{Int}}` cho phép chứa nhiều kích thước itemset, hữu ích với kết quả chung nhưng không phải kiểu cụ thể. Basic và khâu sinh candidate vẫn sử dụng tuple độ dài thay đổi. Vòng đếm chính của Optimized sử dụng vector ID `Int` và tuple hai số nguyên cụ thể. Cần profiling với Julia và xác nhận yêu cầu tránh abstract type trong hot loop; không tuyên bố đã loại hết chi phí dynamic dispatch.
2. Đề viết support của vế trái X đạt minsup. Groceries hiện sinh luật từ frequent union (X ∪ Y đạt minsup), nên X cũng đạt minsup, rồi lọc confidence. Cần xác nhận nếu thầy muốn cả luật có union dưới ngưỡng nhưng X đạt ngưỡng; không tự thay đổi quy ước và kết quả lịch sử.
3. Benchmark hiện tải FIMI, kiểm tra SHA-256; chưa xác minh nguồn Hugging Face/Kaggle tương đương hoặc điều kiện vượt kích thước repository. Không thay dữ liệu chưa đối chiếu.
4. Peak RSS hỗ trợ Linux/macOS; chạy benchmark đầy đủ bằng Colab/WSL khi dùng Windows. Runtime Julia và SPMF có phạm vi đo khác nhau, cần ghi rõ khi phân tích.
5. Các bảng/biểu đồ benchmark, log test và kết quả ứng dụng lưu sẵn thuộc lần chạy trước. Phải chạy lại sau sửa code; không lấy log cũ làm log nghiệm thu.
6. Chưa có Report.pdf theo yêu cầu hoãn báo cáo. Link Colab cần được kiểm tra sau khi push repo public; chạy Run All với môi trường sạch.
7. Đề cho phép AI hỗ trợ nhưng yêu cầu sinh viên hiểu và giải thích được bài làm, đồng thời cấm sao chép. Rà soát và refactor có AI hỗ trợ; nhóm cần tự kiểm tra, hiểu và xác nhận cách sử dụng theo quy định của giảng viên.

## Kiểm tra trong lượt sửa

- Kiểm tra định dạng notebook bằng nbformat và compile toàn bộ cell Python điều phối.
- Đọc toàn bộ Project.toml/Manifest.toml bằng trình phân tích TOML.
- Rà soát import trực tiếp, kiểm tra chuỗi thông báo và các điểm gọi hàm đã thay đổi.
- Chưa chạy Julia, SPMF, benchmark hay Colab: không có Julia trong môi trường, không phân giải được máy chủ tải Julia; Java hiện tại là 21, JAR cần Java 25+.

## Nghiệm thu tiếp theo

```sh
julia --project=evaluation_environment -e 'using Pkg; Pkg.instantiate()'
julia --project=visual_environment -e 'using Pkg; Pkg.instantiate()'
julia --project test/runtests.jl
julia --project=. demo.jl --minsup 0.6 data/toy/sample.txt --implementation optimized
```

Lưu output thật của lần test cuối vào README, chạy lại benchmark và hai ứng dụng theo hướng dẫn, sau đó kiểm tra Colab Run All. Không dùng chế độ core-only để thay cho test đầy đủ.
