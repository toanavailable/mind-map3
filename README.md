# Khủng hoảng "Dọn rác" Đơn hàng cũ

Sau 5 năm hoạt động, bảng `ORDERS` tích tụ hàng trăm nghìn đơn hàng bị hủy (`Status = 'Canceled'`), làm ổ cứng đầy và truy vấn hóa đơn chậm. Cần dọn dẹp các đơn này, nhưng **phòng Kế toán vẫn phải đối soát được lịch sử để kiểm toán cuối năm**.

## 1. Hai giải pháp đề xuất

### Giải pháp 1 – Hard Delete

```sql
DELETE FROM ORDERS
WHERE Status = 'Canceled';
```

Xóa vĩnh viễn các dòng đơn hủy khỏi bảng.

### Giải pháp 2 – Soft Delete

```sql
UPDATE ORDERS
SET IsDeleted = 1
WHERE Status = 'Canceled';
```

Không xóa thật, chỉ bật cờ `IsDeleted = 1`. Ứng dụng bán hàng lọc `WHERE IsDeleted = 0` nên không thấy các đơn này, nhưng dữ liệu vẫn còn nguyên trong bảng.

## 2. So sánh và lựa chọn

| Tiêu chí | Hard Delete (`DELETE`) | Soft Delete (`UPDATE IsDeleted = 1`) |
|---|---|---|
| **Giải phóng dung lượng ổ cứng** | ✅ Giảm số dòng, có không gian để tái sử dụng (`OPTIMIZE TABLE` để thu hồi hẳn) | ❌ Không giảm, dữ liệu vẫn nằm trong bảng và còn thêm cột cờ |
| **Tốc độ truy vấn** | ✅ Bảng nhỏ hơn nên truy vấn nhanh hơn, không cần thêm điều kiện lọc | ⚠️ Bảng không nhỏ đi. Mọi truy vấn phải thêm `WHERE IsDeleted = 0`. Cần chỉ mục để giữ tốc độ |
| **Tính vẹn toàn lịch sử kế toán** | ❌ Mất vĩnh viễn, Kế toán không thể đối soát. Vi phạm yêu cầu kiểm toán | ✅ Giữ nguyên toàn bộ lịch sử, đối soát bất cứ lúc nào |
| **Khả năng khôi phục** | ❌ Chỉ khôi phục được từ bản sao lưu | ✅ Chỉ cần đặt lại `IsDeleted = 0` |
| **Rủi ro thao tác** | Cao: viết sai `WHERE` là mất dữ liệu thật | Thấp: sai thì `UPDATE` ngược lại là xong |
| **Độ phức tạp cho lập trình viên** | Thấp | Trung bình: phải nhớ lọc `IsDeleted = 0` ở mọi truy vấn |

### Chốt giải pháp: Soft Delete

Với vai trò Kỹ sư trưởng, mình chọn **Soft Delete**. Lý do:

1. **Yêu cầu kiểm toán là ràng buộc bắt buộc.** Hard Delete làm mất vĩnh viễn dữ liệu Kế toán cần, nên bị loại ngay dù giải phóng được dung lượng.
2. **An toàn và đảo ngược được.** Nếu đánh dấu nhầm, có thể khôi phục ngay mà không cần bản sao lưu.
3. **Khắc phục được nhược điểm về tốc độ** bằng cách tạo chỉ mục trên cột cờ. Khi đó ứng dụng bán hàng chỉ quét các đơn còn hiệu lực.

Nhược điểm về dung lượng ổ cứng vẫn còn. Phần mở rộng ở mục 5 trình bày cách xử lý khi dữ liệu tiếp tục phình to.

## 3. Triển khai Soft Delete

### Bước 1 – Thêm cột ghi thời điểm ẩn đơn

```sql
ALTER TABLE ORDERS
ADD DeletedAt DATETIME NULL;
```

Cột này cho biết đơn được ẩn khi nào, giúp ích cho kiểm toán.

### Bước 2 – Kiểm tra trước những đơn sẽ bị đánh dấu

```sql
SELECT OrderID, CustomerName, Status
FROM ORDERS
WHERE Status = 'Canceled' AND IsDeleted = 0;
```

### Bước 3 – Đánh dấu ẩn trong transaction

```sql
START TRANSACTION;

UPDATE ORDERS
SET IsDeleted = 1,
    DeletedAt = NOW()
WHERE Status = 'Canceled'
  AND IsDeleted = 0;

COMMIT;
```

- Điều kiện `IsDeleted = 0` tránh cập nhật lại những đơn đã ẩn từ trước.
- Với hàng trăm nghìn dòng, nên thêm `LIMIT 10000` và chạy lặp lại đến khi không còn dòng nào bị ảnh hưởng. Cách này tránh khóa bảng quá lâu khi hệ thống đang bán hàng.
- Trong MySQL Workbench, Safe Update Mode có thể chặn lệnh này vì `WHERE` không dùng khóa chính. Khi đó chạy `SET SQL_SAFE_UPDATES = 0;` trước.

### Bước 4 – Tạo chỉ mục để giữ tốc độ truy vấn

```sql
CREATE INDEX idx_orders_isdeleted_orderdate
    ON ORDERS (IsDeleted, OrderDate);
```

Ứng dụng bán hàng thường lọc `IsDeleted = 0` và sắp xếp hoặc lọc theo ngày. Chỉ mục này giúp MySQL bỏ qua toàn bộ nhóm đơn đã ẩn thay vì quét cả bảng.

## 4. Kết quả

**Ứng dụng bán hàng:** đơn hủy "biến mất".

```sql
SELECT * FROM ORDERS WHERE IsDeleted = 0;
```

| OrderID | CustomerName | OrderDate | TotalAmount | Status |
|---|---|---|---|---|
| 1 | Nguyễn Văn A | 2023-01-10 | 500000.00 | Completed |
| 4 | Lê Văn C | 2024-01-05 | 850000.00 | Completed |

**Kế toán:** đơn hủy vẫn còn để đối soát.

```sql
SELECT * FROM ORDERS WHERE Status = 'Canceled';
```

| OrderID | CustomerName | OrderDate | TotalAmount | Status | IsDeleted |
|---|---|---|---|---|---|
| 2 | Khách hàng vãng lai | 2023-02-15 | 1200000.00 | Canceled | 1 |
| 3 | Trần Thị B | 2023-05-20 | 300000.00 | Canceled | 1 |

**Khôi phục khi ẩn nhầm:**

```sql
UPDATE ORDERS SET IsDeleted = 0, DeletedAt = NULL WHERE OrderID = 2;
```

## 5. Mở rộng: kết hợp lưu trữ (Archive) khi dữ liệu tiếp tục phình to

Nếu sau này ổ cứng vẫn quá tải, có thể chuyển các đơn đã ẩn quá lâu (ví dụ hơn 2 năm) sang một **bảng lưu trữ** riêng, rồi mới xóa khỏi bảng chính. Cách này vừa giải phóng bảng `ORDERS`, vừa giữ lịch sử cho Kế toán:

```sql
CREATE TABLE ORDERS_ARCHIVE LIKE ORDERS;

SET @cutoff = NOW() - INTERVAL 2 YEAR;  -- chốt mốc thời gian dùng chung cho 2 lệnh

START TRANSACTION;

INSERT INTO ORDERS_ARCHIVE
SELECT * FROM ORDERS
WHERE IsDeleted = 1 AND DeletedAt < @cutoff;

DELETE FROM ORDERS
WHERE IsDeleted = 1 AND DeletedAt < @cutoff;

COMMIT;
```

Bảng lưu trữ có thể đặt trên ổ lưu trữ giá rẻ, vì Kế toán chỉ truy cập vào cuối năm.
