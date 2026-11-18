# Giao diện chung để chạy thuật toán khai thác tập phổ biến.
#
# transactions: cơ sở dữ liệu đã chuẩn hóa.
# minimum_support: minimum support dạng tỷ lệ.
# implementation: phiên bản thuật toán.
#
# :basic     -> Apriori-TID cơ bản.
# :optimized -> Apriori-TID với ID và chỉ mục tập sinh.
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

    if implementation == :optimized
        return mine_apriori_tid_optimized(transactions, minimum_support_count)
    end

    # Báo lỗi nếu tên phiên bản không hợp lệ.
    throw(ArgumentError("Implementation must be :basic or :optimized."))
end
