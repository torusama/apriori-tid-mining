# Phân tích kết quả Visual Pattern Mining

Có 20 ảnh/giao dịch; số visual word trung bình mỗi ảnh là 7.95.

Giao dịch khá dày: trung bình mỗi ảnh chứa phần lớn trong 8 word đã xuất hiện. Các itemset support cao có thể ít phân biệt ảnh; cần thử thêm cấu hình khác để đánh giá.

- Minsup 0.7: 255 tập phổ biến.
- Minsup 0.8: 255 tập phổ biến.
- Minsup 0.9: 255 tập phổ biến.

- Itemset {1 2} xuất hiện trong 20 ảnh; ví dụ: image_0001, image_0002, image_0003, image_0004, image_0005.
- Itemset {1 2 4} xuất hiện trong 20 ảnh; ví dụ: image_0001, image_0002, image_0003, image_0004, image_0005.
- Itemset {1 2 5} xuất hiện trong 20 ảnh; ví dụ: image_0001, image_0002, image_0003, image_0004, image_0005.

Các mã visual word là cụm SIFT, không bảo đảm tương ứng bộ phận có ý nghĩa của hoa. K, seed và tiền xử lý ảnh ảnh hưởng kết quả; cách biểu diễn tập bỏ qua vị trí và số lần lặp. Đồng xuất hiện không chứng minh khả năng phân loại. Chưa phân tích theo nhãn lớp.
