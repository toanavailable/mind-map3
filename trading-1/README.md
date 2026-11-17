# Thảm họa "Đồng giá toàn siêu thị"

Phân tích lỗi lệnh `UPDATE` khiến toàn bộ 10.000 mặt hàng trong siêu thị bị giảm giá 10%, và viết lại câu lệnh đúng nghiệp vụ của phòng Marketing.

## 1. Bối cảnh

- **Yêu cầu của Marketing:** giảm giá 10% cho tất cả sản phẩm thuộc ngành hàng **Điện tử (Electronics)**.
- **Thực tế:** sau khi script chạy, **toàn bộ** mặt hàng (rau, sữa, tivi…) đều bị giảm 10%. Hệ thống bán hàng phải tạm ngưng khẩn cấp.

Đoạn code gây lỗi:

```sql
UPDATE PRODUCTS
SET OriginalPrice = OriginalPrice * 0.9;
```

## 2. Phân tích nguyên nhân

### Thiếu mệnh đề `WHERE`

Lệnh `UPDATE` có cấu trúc `UPDATE bảng SET cột = giá trị WHERE điều kiện;`. Trong đó, `WHERE` quyết định **những dòng nào** bị sửa. Nếu **không có `WHERE`**, MySQL áp dụng thay đổi cho **mọi dòng trong bảng**.

Câu lệnh của thực tập sinh vẫn **đúng cú pháp**, nên MySQL chạy mà không báo lỗi hay cảnh báo gì. Đó là lý do nó là "con dao hai lưỡi": phép tính `OriginalPrice * 0.9` đúng, nhưng phạm vi áp dụng sai hoàn toàn.

### Dò luồng (trace) với dữ liệu mẫu

| ProductID | ProductName | Category | Giá ban đầu | Sau code lỗi | Mong muốn |
|---|---|---|---|---|---|
| 1 | iPhone 15 | Electronics | 20.000.000 | 18.000.000 ✅ | 18.000.000 |
| 2 | Samsung Refrigerator | Electronics | 15.000.000 | 13.500.000 ✅ | 13.500.000 |
| 3 | Water Spinach | Food | 10.000 | 9.000 ❌ | 10.000 |
| 4 | Filtered Fresh Milk 4 | Food | 28.000 | 25.200 ❌ | 28.000 |

Các dòng `Food` bị giảm giá dù không thuộc chương trình khuyến mãi. Với 10.000 mặt hàng, phần lớn là hàng không thuộc ngành Điện tử, nên siêu thị bán lỗ trên diện rộng và lợi nhuận "bay màu".

### Các thiếu sót khác trong quy trình

- **Không sao lưu** trước khi cập nhật, nên không còn giá gốc để khôi phục.
- **Không chạy `SELECT` kiểm tra trước**, nên không biết câu lệnh sẽ ảnh hưởng bao nhiêu dòng.
- **Không dùng transaction**: MySQL mặc định tự lưu (autocommit), nên không thể `ROLLBACK`.
- **Chạy thẳng trên hệ thống thật**, không thử trước trên môi trường test.

## 3. Mã lệnh đã sửa

```sql
UPDATE PRODUCTS
SET OriginalPrice = OriginalPrice * 0.9
WHERE Category = 'Electronics';
```

Mệnh đề `WHERE Category = 'Electronics'` giới hạn đúng phạm vi: chỉ sản phẩm ngành Điện tử bị giảm giá, các ngành khác giữ nguyên. Như vậy là "đúng người, đúng tội".

### Quy trình cập nhật an toàn

```sql
-- 1. Sao lưu trước khi cập nhật
CREATE TABLE PRODUCTS_BACKUP AS
SELECT * FROM PRODUCTS;

-- 2. Kiểm tra trước những dòng sẽ bị ảnh hưởng
SELECT ProductID, ProductName, Category, OriginalPrice,
       OriginalPrice * 0.9 AS GiaSauGiam
FROM PRODUCTS
WHERE Category = 'Electronics';

-- 3. Cập nhật trong transaction để có thể hoàn tác
START TRANSACTION;

UPDATE PRODUCTS
SET OriginalPrice = OriginalPrice * 0.9
WHERE Category = 'Electronics';

SELECT * FROM PRODUCTS;   -- kiểm tra lại kết quả

COMMIT;      -- đúng thì lưu
-- ROLLBACK; -- sai thì hoàn tác
```

Kết quả sau khi chạy với dữ liệu mẫu:

| ProductID | ProductName | Category | OriginalPrice |
|---|---|---|---|
| 1 | iPhone 15 | Electronics | 18.000.000,00 |
| 2 | Samsung Refrigerator | Electronics | 13.500.000,00 |
| 3 | Water Spinach | Food | 10.000,00 |
| 4 | Filtered Fresh Milk 4 | Food | 28.000,00 |

## 4. Bài học rút ra

- Với lệnh `UPDATE` / `DELETE`, **luôn viết `WHERE` trước** rồi mới viết phần còn lại.
- Bật **Safe Update Mode** (`SET SQL_SAFE_UPDATES = 1;`) để MySQL tự chặn các lệnh `UPDATE`/`DELETE` không có `WHERE` theo khóa.
- Áp dụng quy trình **sao lưu → `SELECT` kiểm tra → transaction → `COMMIT`/`ROLLBACK`** cho mọi thay đổi dữ liệu quan trọng.
- Về thiết kế: không nên ghi đè trực tiếp lên cột `OriginalPrice` (giá gốc). Nên tách thêm cột `SalePrice` hoặc bảng khuyến mãi riêng, để khi hết chương trình vẫn còn giá gốc.
