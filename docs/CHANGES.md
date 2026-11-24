# Tổng quan cài đặt

## Thuật toán và dữ liệu

- Hai phiên bản Basic/Optimized dùng chung candidate generation, pruning, hợp đồng dữ liệu và quy tắc support.
- Basic tính trước hai tập sinh cho mỗi ứng viên ở từng cấp. Optimized dùng ID nguyên, chỉ mục theo tập sinh thứ nhất và mảng đánh dấu để giảm số phép kiểm tra ở mỗi bản ghi.
- Ngưỡng count được tính bằng phân số chính xác từ biểu diễn thập phân của minsup, tránh sai biên do số thực nhị phân.
- Reader/writer SPMF đóng file rõ ràng, chuẩn hóa item và giữ nguyên giao dịch trùng.
- CLI nhận đường dẫn positional hoặc `--input`, hỗ trợ `--output`, `--implementation`, `--minsup` và `--help`.

## Đánh giá

- SPMF chạy như công cụ tham chiếu độc lập; đối chiếu từng itemset/count và ghi riêng số thiếu, thừa, sai support.
- Để bảo đảm cùng threshold nguyên, SPMF nhận tỷ lệ nằm giữa khoảng có cùng ceil. JAR/input/output được đặt trong thư mục tạm với tên ASCII khi gọi Java.
- Benchmark có năm minsup trên bốn dataset, warm-up và ba lượt đo, peak RSS, Retail scaling và dữ liệu tổng hợp thay đổi độ dài giao dịch.
- Các công cụ tải dữ liệu và vẽ biểu đồ dùng Julia. Trục runtime dùng log khi mọi giá trị dương; nhãn minsup biểu diễn phần trăm.

## Ứng dụng

- Groceries tạo transaction từ ma trận hiện diện danh mục, sinh luật và tính support/confidence/lift; top 10 được xếp theo lift.
- Flowers-17 dùng ORB và K-Means, giữ ảnh không descriptor trong mẫu số support, ghi coverage/độ bão hòa và đếm lại support khi chọn ảnh minh họa.
- Cả hai ứng dụng gọi thuật toán do nhóm cài đặt; SPMF không sinh kết quả ứng dụng thay cho thuật toán.

## Tài liệu và báo cáo

- Notebook kernel Python điều phối script Julia cho test, benchmark và hai ứng dụng.
- Báo cáo IEEE tiếng Việt.
