# Ghi chú tích hợp và kiểm thử cần thực hiện

## Thay đổi

- `notebooks/demo.ipynb`: thay hai notebook riêng bằng một demo kernel Python gọi Julia, có toy example, test, benchmark lịch sử, Groceries và Flowers-17. Demo có cấu hình ảnh K=8 và K=16.
- `src/utils.jl`: quy đổi số thập phân thành phân số chính xác trước khi tính support count. Không trừ epsilon tùy tiện vì có thể bỏ sai ngưỡng thực sự lớn hơn biên.
- `src/evaluation/compare_spmf.jl`: copy cả JAR, input và output qua thư mục tạm, dùng tên ASCII; đưa SPMF một tỷ lệ ở giữa khoảng có cùng support count nguyên. Ví dụ với 100.000 giao dịch, ngưỡng 3.500 được đối chiếu bằng 3,4995% (cùng ceil là 3.500). Không dùng SPMF thay thuật toán nhóm.
- `src/algorithm/spmf_io.jl`: đóng file rõ ràng bằng `open do`, kể cả khi đọc lỗi.
- `src/algorithm/apriori_tid_optimized.jl`: vòng lặp tường minh, biến tên đầy đủ, chú thích hai tập sinh và mảng đánh dấu; giữ nguyên thiết kế ID số, không chuyển về bản Basic.
- `src/applications/association_rules.jl`: giải thích hai nhánh đệ quy sinh luật và đổi tên biến.
- `scripts/fetch_datasets.jl`, `scripts/plot_results.jl` và `src/evaluation/plot_results.jl`: tải dữ liệu và vẽ bằng Julia; bỏ hai script Python. Gói phụ trợ nằm trong `evaluation_environment`.
- `scripts/visual_pipeline.jl`: thêm tỷ lệ ảnh chứa đủ visual words và diễn giải cách dùng pattern; giữ đúng mẫu số gồm ảnh rỗng.
- `scripts/run_all_tests.jl`: chạy test core + SPMF và test ảnh trong hai môi trường phù hợp. Thêm test cho minsup đúng biên, ngay trên biên và đường dẫn có dấu.
- README: cập nhật lệnh, link notebook, hướng dẫn Java, bỏ link tài liệu không tồn tại và phân biệt kết quả cũ với kết quả cần đo lại.

## Kiểm tra đã thực hiện trong môi trường chỉnh sửa

- Đọc mã nguồn, kiểm tra liên kết và cấu trúc file; xác thực schema notebook bằng nbformat, kiểm tra cú pháp các cell Python điều phối.
- Kiểm tra class file trong SPMF JAR: major version 69 (Java 25); chạy với Java 21 hiện có cho lỗi UnsupportedClassVersionError. Không có Julia trong môi trường này, không truy cập được máy chủ tải Julia. Do đó chưa chạy được test Julia, đồ thị mới, SPMF hay Colab Run All.
- Không sửa số liệu benchmark hoặc log kiểm thử lịch sử. Code đã thay đổi nên các số liệu đó không phải bằng chứng chạy bản mới.

## Việc nhóm cần thực hiện trước khi nộp

1. Cài Julia 1.10+ và Java 25+; instantiate hai môi trường phụ trợ.
2. Chạy `julia --project=. scripts/run_all_tests.jl`, lưu output thật và chèn README. Thử trên Windows nếu cần xác nhận lỗi đường dẫn và EBUSY.
3. Chạy lại benchmark với `result/benchmark_new`, kiểm tra riêng ngưỡng T10I4D100K 3,5%; chạy lại hai ứng dụng, vẽ biểu đồ Julia và so sánh hai cấu hình ảnh.
4. Push nhánh nộp lên GitHub, xác nhận link Colab công khai và Run All. Nếu chưa push, upload ZIP vào Colab với tên `apriori-tid-mining.zip`.
5. Bổ sung nguồn Hugging Face/Kaggle đúng bộ dữ liệu và hoàn thành Report.pdf sau; xác nhận với giảng viên việc dùng AI hỗ trợ và các gói Julia ngoài phần thuật toán.

## Ghi chú ZIP

ZIP tích hợp không kèm `.git` để tránh ghi đè lịch sử Git đang có trên máy. File nén ảnh gốc `data/raw/flowers/17flowers.tgz` được giữ; bỏ ảnh đã giải nén (có thể tạo lại từ archive), cache và các thư mục kết quả Python cũ. Khi áp dụng vào repo đang có, xóa thủ công hai notebook cũ và hai script Python cũ nếu giải nén theo kiểu chép đè, vì thao tác chép đè không tự xóa file. Giữ `.git` hiện tại của nhóm.

## Bản tích hợp tiếp theo

- `demo.jl` và CLI nhận đường dẫn positional theo ví dụ đề; vẫn hỗ trợ `--input`, `--output`, `--implementation`. Có `--help`, output mặc định và test hồi quy CLI.
- `test/runtests.jl` là điểm vào đầy đủ (core, SPMF, ảnh). Chế độ `--core-only` được ghi rõ là không đủ để nghiệm thu. Notebook tự chuẩn bị Java 25+ trên Colab nếu cần.
- Notebook tải đủ bốn benchmark bằng Julia, kiểm tra SHA-256 bản chuẩn hóa, đối chiếu Basic/Optimized với SPMF tại một mức minsup mỗi bộ. Có tùy chọn chạy toàn bộ benchmark và vẽ biểu đồ mới; không ghi đè kết quả lịch sử.
- Không thay dataset và không push dữ liệu gốc. Chưa thêm nguồn Hugging Face/Kaggle vì chưa xác minh được bản tương đương; nếu vượt kích thước repo cần thực hiện theo đề.
- Chưa chạy Julia/Java 25 hay Colab Run All trong môi trường chỉnh sửa; không tạo log pass giả.
