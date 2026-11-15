# Giao diện chung để chạy thuật toán khai thác tập phổ biến.
#
# transactions: cơ sở dữ liệu đã chuẩn hóa.
# minimum_support: minimum support dạng tỷ lệ.
# implementation: phiên bản thuật toán.
#
# :basic     -> Apriori-TID cơ bản.
# :optimized -> phiên bản tối ưu sẽ viết ở TASK 03.
function mine(
    transactions::Transactions;
    minimum_support::Real = 0.4,
    implementation::Symbol = :basic
)::MiningResult

    # Kiểm tra dữ liệu đầu vào.
    validate_transactions(transactions)

    # Chuyển minimum support từ tỷ lệ sang support count.
    minimum_support_count = calculate_minimum_support_count(
        minimum_support,
        length(transactions)
    )

    # Chạy thuật toán Apriori-TID cơ bản.
    if implementation == :basic

        return mine_apriori_tid(
            transactions,
            minimum_support_count
        )
    end

    # Phiên bản tối ưu sẽ được triển khai ở TASK 03.
    if implementation == :optimized

        error("Optimized Apriori-TID has not been implemented yet.")
    end

    # Báo lỗi nếu tên phiên bản không hợp lệ.
    throw(ArgumentError("Implementation must be :basic or :optimized."))
end