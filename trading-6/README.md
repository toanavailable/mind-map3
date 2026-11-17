# Quản lý hệ thống bán hàng Shop thời trang

Bài tập tổng hợp toàn bộ quy trình làm việc với MySQL: **thiết kế bảng (DDL) → nạp dữ liệu (INSERT) → hiệu chỉnh (UPDATE/DELETE) → khai thác thông tin (SELECT)**. Bài cũng có phần nhận diện và xử lý dữ liệu lỗi trong thực tế.

## Phần 1: Thiết kế bảng

```sql
CREATE TABLE products (
    product_id   CHAR(3)        NOT NULL,
    product_name VARCHAR(100)   NOT NULL,
    size         VARCHAR(5)     NOT NULL,
    price        DECIMAL(12, 2) NOT NULL,
    CONSTRAINT pk_products        PRIMARY KEY (product_id),
    CONSTRAINT chk_products_size  CHECK (size IN ('XS', 'S', 'M', 'L', 'XL', 'XXL')),
    CONSTRAINT chk_products_price CHECK (price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

| Cột | Kiểu dữ liệu | Ràng buộc | Lý do chọn |
|---|---|---|---|
| `product_id` | `CHAR(3)` | `PRIMARY KEY` | Mã luôn dài đúng 3 ký tự (`P01`, `P02`…) nên dùng kiểu cố định |
| `product_name` | `VARCHAR(100)` | `NOT NULL` | Tên dài ngắn khác nhau, sản phẩm bắt buộc phải có tên |
| `size` | `VARCHAR(5)` | `NOT NULL`, `CHECK (size IN (...))` | Chỉ chấp nhận các size chuẩn, không để trống |
| `price` | `DECIMAL(12, 2)` | `NOT NULL`, `CHECK (price > 0)` | Tiền tệ cần chính xác tuyệt đối. Giá phải dương |

Bảng dùng `utf8mb4` để lưu đúng tên sản phẩm tiếng Việt có dấu.

## Phần 2: Nạp dữ liệu

```sql
INSERT INTO products (product_id, product_name, size, price) VALUES
    ('P01', 'Áo sơ mi trắng', 'L',  250000),
    ('P02', 'Quần Jean xanh', 'M',  450000),
    ('P03', 'Áo thun Basic',  'XL', 150000);
```

### Dữ liệu lỗi: P04 – Áo hoodie, NULL, -200000

```sql
INSERT INTO products (product_id, product_name, size, price) VALUES
    ('P04', 'Áo hoodie', NULL, -200000);
```

Dòng này có **hai lỗi dữ liệu** và bị ràng buộc từ chối:

| Lỗi | Ràng buộc chặn | Thông báo MySQL |
|---|---|---|
| `size` bị bỏ trống (NULL) | `NOT NULL` | `Error 1048: Column 'size' cannot be null` |
| `price` âm (-200000) | `CHECK (price > 0)` | `Error 3819: Check constraint 'chk_products_price' is violated` |

Nếu không có ràng buộc, shop sẽ có một sản phẩm "bán kèm tiền": khách mua áo hoodie được shop trả 200.000đ, và nhãn in ra thì thiếu size. P04 được **tách thành lệnh `INSERT` riêng**. Nếu gộp chung với P01–P03 trong một lệnh, cả lệnh sẽ thất bại và không dòng nào được thêm. Cần liên hệ chủ shop để xác nhận size và giá đúng trước khi nhập lại.

## Phần 3: Thay đổi từ thực tế

### 3.1 Giảm giá P02 còn 400000

```sql
UPDATE products
SET price = 400000
WHERE product_id = 'P02';
```

`WHERE` theo khóa chính đảm bảo chỉ đúng sản phẩm P02 bị sửa.

### 3.2 Tăng giá toàn bộ sản phẩm lên 10%

```sql
SET SQL_SAFE_UPDATES = 0;

UPDATE products
SET price = price * 1.1;

SET SQL_SAFE_UPDATES = 1;
```

- Ở đây **cố ý không có `WHERE`**, vì yêu cầu áp dụng cho **toàn bộ** sản phẩm.
- Safe Update Mode (mặc định bật trong MySQL Workbench) chặn lệnh `UPDATE` không có `WHERE` theo khóa. Vì vậy cần tạm tắt chế độ này, rồi **bật lại ngay** sau khi chạy xong.

Bảng giá sau Phần 3:

| product_id | product_name | Giá ban đầu | Sau 3.1 | Sau 3.2 |
|---|---|---|---|---|
| P01 | Áo sơ mi trắng | 250.000 | 250.000 | **275.000** |
| P02 | Quần Jean xanh | 450.000 | 400.000 | **440.000** |
| P03 | Áo thun Basic | 150.000 | 150.000 | **165.000** |

> ⚠️ **Bẫy toán học:** tăng 10% **không** khôi phục được giá gốc sau khi đã giảm 10%. Giá đã giảm là `x × 0,9`. Tăng 10% cho ra `x × 0,9 × 1,1 = 0,99x`, tức vẫn **thấp hơn giá gốc 1%**. Ví dụ: 100.000 → giảm 10% còn 90.000 → tăng 10% thành 99.000. Muốn khôi phục đúng giá gốc phải **chia cho 0,9**: `SET price = price / 0.9`. Bài làm thực hiện đúng yêu cầu của đề (tăng 10%), nhưng cần báo lại chủ shop điểm này.

## Phần 4: Xóa sản phẩm ngừng kinh doanh

```sql
DELETE FROM products
WHERE product_id = 'P03';
```

`WHERE` theo khóa chính đảm bảo chỉ xóa đúng P03. Nếu thiếu `WHERE`, toàn bộ sản phẩm của shop sẽ bị xóa.

Trong thực tế, nếu P03 đã từng xuất hiện trong hóa đơn, nên dùng **Soft Delete** (thêm cột `is_active` và đặt về 0) để giữ lịch sử bán hàng, thay vì xóa thật.

## Phần 5: Truy vấn phục vụ kinh doanh

### 5.1 Xem toàn bộ sản phẩm

```sql
SELECT * FROM products;
```

| product_id | product_name | size | price |
|---|---|---|---|
| P01 | Áo sơ mi trắng | L | 275000.00 |
| P02 | Quần Jean xanh | M | 440000.00 |

### 5.2 In nhãn sản phẩm (chỉ cần Tên, Size)

```sql
SELECT product_name, size
FROM products;
```

| product_name | size |
|---|---|
| Áo sơ mi trắng | L |
| Quần Jean xanh | M |

Chỉ lấy đúng 2 cột cần in, không dùng `SELECT *`.

### 5.3 Tìm sản phẩm giá > 300000

```sql
SELECT product_id, product_name, size, price
FROM products
WHERE price > 300000;
```

| product_id | product_name | size | price |
|---|---|---|---|
| P02 | Quần Jean xanh | M | 440000.00 |

## Tổng kết lỗi và cách phòng tránh

| Tình huống | Rủi ro | Cách phòng tránh |
|---|---|---|
| Size NULL, giá âm (P04) | Dữ liệu vô nghĩa, bán lỗ | `NOT NULL`, `CHECK` ngay từ lúc thiết kế bảng |
| Gộp dòng lỗi chung với dòng đúng trong một `INSERT` | Cả lệnh thất bại | Tách riêng dòng nghi ngờ, hoặc làm sạch dữ liệu trước |
| `UPDATE` / `DELETE` thiếu `WHERE` | Sửa hoặc xóa toàn bộ bảng | Luôn có `WHERE` theo khóa chính, chỉ bỏ khi cố ý áp dụng cho toàn bảng |
| Tăng 10% để "khôi phục" giá đã giảm 10% | Giá vẫn thấp hơn gốc 1% | Khôi phục bằng phép chia `/ 0.9`, hoặc lưu riêng cột giá gốc |
