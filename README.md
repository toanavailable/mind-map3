# Trích xuất Dữ liệu Khách hàng "Ngủ đông"

Dịch yêu cầu của Giám đốc sang câu lệnh `SELECT`: lấy **Tên** và **Email** của khách hàng ở **Hà Nội** đã **không mua hàng hơn 6 tháng** (tính từ 01/04/2026 về trước) để gửi email kích cầu. Câu lệnh phải loại bỏ các "bẫy dữ liệu" có thể làm hệ thống gửi thư bị crash.

## 1. Phân tích bài toán (I/O)

| | Nội dung |
|---|---|
| **Input** | Bảng `CUSTOMERS` (hàng triệu bản ghi, hàng chục cột) |
| **Cột dùng để lọc** | `City`, `LastPurchaseDate`, `Email`, `Status` |
| **Output** | Chỉ 2 cột: `FullName`, `Email` |

### Vì sao `SELECT *` là sai lầm gây nghẽn cổ chai?

- **Lấy thừa dữ liệu:** Sếp chỉ cần 2 cột, nhưng `SELECT *` lấy toàn bộ cột (ngày sinh, giới tính, địa chỉ, điểm…). Với hàng triệu dòng, lượng dữ liệu phải đọc từ đĩa tăng lên nhiều lần.
- **Tốn băng thông mạng và bộ nhớ:** toàn bộ khối dữ liệu thừa phải truyền từ máy chủ CSDL sang hệ thống gửi thư, làm chậm cả hai bên và dễ tràn bộ nhớ.
- **Mất lợi thế chỉ mục:** khi chỉ lấy vài cột, MySQL có thể đọc trực tiếp từ index. `SELECT *` thì luôn phải đọc cả dòng.
- **Hỏng hệ thống nhận dữ liệu:** công cụ gửi thư chỉ chờ 2 cột Tên và Email. Nhận về hàng chục cột có thể làm sai định dạng import.
- **Lộ dữ liệu cá nhân không cần thiết:** ngày sinh, địa chỉ… bị chuyển sang hệ thống khác mà không có lý do.

## 2. Thiết kế giải pháp: logic lọc trong WHERE

| # | Yêu cầu | Điều kiện | Giải thích |
|---|---|---|---|
| 1 | Khách ở Hà Nội | `City = 'Hà Nội'` | Loại khách ở tỉnh khác |
| 2 | Không mua hàng hơn 6 tháng tính từ 01/04/2026 | `LastPurchaseDate < DATE_SUB('2026-04-01', INTERVAL 6 MONTH)` | Lùi 6 tháng từ 01/04/2026 được mốc **01/10/2025**. Lần mua cuối phải trước mốc này |
| 3 | Có email (bẫy NULL) | `Email IS NOT NULL` | Phải dùng `IS NOT NULL`. Viết `Email <> NULL` sẽ luôn sai vì mọi phép so sánh với NULL đều cho kết quả UNKNOWN |
| 4 | Email không rỗng | `TRIM(Email) <> ''` | Chặn email là chuỗi rỗng hoặc chỉ toàn khoảng trắng |
| 5 | Tài khoản đang hoạt động (bẫy Locked) | `Status = 'Active'` | Chọn đúng trạng thái hợp lệ thay vì loại trừ `'Locked'`, nên cũng loại được các trạng thái lạ khác hoặc NULL |

Tất cả điều kiện được nối bằng `AND`, vì khách hàng phải thỏa mãn **đồng thời** cả 5 điều kiện.

## 3. Triển khai code

```sql
SELECT FullName, Email
FROM CUSTOMERS
WHERE City = 'Hà Nội'
  AND LastPurchaseDate < DATE_SUB('2026-04-01', INTERVAL 6 MONTH)  -- < '2025-10-01'
  AND Email IS NOT NULL
  AND TRIM(Email) <> ''
  AND Status = 'Active';
```

### Dò luồng với dữ liệu mẫu

| Khách hàng | City | LastPurchaseDate | Email | Status | Kết quả | Lý do |
|---|---|---|---|---|---|---|
| Nguyễn Văn A | Hà Nội | 2025-05-20 | anv@gmail.com | Active | ✅ Lấy | Thỏa mãn tất cả điều kiện |
| Trần Thị B | Hà Nội | 2026-02-10 | btt@gmail.com | Active | ❌ Loại | Mới mua hàng (sau 01/10/2025) |
| Lê Văn C | Hà Nội | 2025-01-15 | NULL | Active | ❌ Loại | Không có email |
| Phạm Minh D | Hà Nội | 2024-12-01 | dpm@gmail.com | Locked | ❌ Loại | Tài khoản bị khóa |
| Hoàng An E | TP HCM | 2025-03-01 | eha@gmail.com | Active | ❌ Loại | Không ở Hà Nội |

Kết quả:

| FullName | Email |
|---|---|
| Nguyễn Văn A | anv@gmail.com |

### Tối ưu cho bảng hàng triệu dòng

Tạo chỉ mục trên các cột lọc, để MySQL tìm thẳng tới đúng nhóm khách hàng thay vì quét toàn bộ bảng:

```sql
CREATE INDEX idx_customers_city_status_lastpurchase
    ON CUSTOMERS (City, Status, LastPurchaseDate);
```

## 4. Lưu ý

- **Khách chưa từng mua hàng** (`LastPurchaseDate` là NULL) không được lấy ra, vì `NULL < '2025-10-01'` cho kết quả UNKNOWN. Nếu Marketing muốn gửi cả nhóm này, thêm điều kiện `OR LastPurchaseDate IS NULL` (đặt trong ngoặc).
- **Dữ liệu thành phố phải nhất quán:** nếu bảng lẫn các cách ghi như `'Ha Noi'` hay `'HN'`, câu lệnh sẽ bỏ sót khách. Nên chuẩn hóa dữ liệu, hoặc dùng bảng danh mục thành phố với khóa ngoại.
- Bảng dùng `utf8mb4`, nên trong MySQL có thể viết trực tiếp `'Hà Nội'` mà không cần tiền tố `N'...'` như SQL Server.
