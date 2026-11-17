# Module "Giỏ Hàng Điện Tử" (Shopping Cart)

Thiết kế nhóm lệnh DML vận hành giỏ hàng trên ứng dụng mua sắm của siêu thị, gồm 4 thao tác cốt lõi: **thêm vào giỏ, xem giỏ, đổi số lượng, xóa khỏi giỏ**. Thiết kế xử lý các bẫy dữ liệu và đảm bảo người dùng này không can thiệp được vào giỏ hàng của người khác.

## 1. Thiết kế dữ liệu

Bảng giỏ hàng theo đề bài:

```sql
CREATE TABLE CART_ITEMS (
    CartItemID INT PRIMARY KEY AUTO_INCREMENT,
    UserID     INT,
    ProductID  INT,
    Quantity   INT,
    AddedDate  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Bảng gốc chưa có ràng buộc nào để chặn dữ liệu sai, nên được gia cố thêm như sau:

```sql
ALTER TABLE CART_ITEMS
    MODIFY UserID    INT NOT NULL,
    MODIFY ProductID INT NOT NULL,
    MODIFY Quantity  INT NOT NULL DEFAULT 1,
    ADD CONSTRAINT uq_cart_user_product UNIQUE (UserID, ProductID),
    ADD CONSTRAINT chk_cart_quantity    CHECK (Quantity BETWEEN 1 AND 99),
    ADD CONSTRAINT fk_cart_user    FOREIGN KEY (UserID)    REFERENCES USERS (UserID) ON DELETE CASCADE,
    ADD CONSTRAINT fk_cart_product FOREIGN KEY (ProductID) REFERENCES PRODUCTS (ProductID);
```

| Ràng buộc | Mục đích |
|---|---|
| `UNIQUE (UserID, ProductID)` | Mỗi người chỉ có **một dòng** cho mỗi mặt hàng. Đây là nền tảng để xử lý bẫy "thêm trùng" |
| `CHECK (Quantity BETWEEN 1 AND 99)` | Chặn số lượng âm, bằng 0 hoặc lớn bất thường |
| `NOT NULL` | Không có dòng giỏ hàng thiếu người dùng, sản phẩm hay số lượng |
| `FOREIGN KEY` | Chỉ thêm được sản phẩm có thật vào giỏ của người dùng có thật |

Trong code, `@user_id` và `@product_id` đại diện cho tham số mà ứng dụng truyền vào. `@user_id` luôn là **người đang đăng nhập**, lấy từ phiên đăng nhập chứ không lấy từ dữ liệu người dùng gửi lên.

## 2. Xử lý bẫy dữ liệu (Edge Cases)

### Bẫy 1 – Khách cố tình nhập số lượng âm (ví dụ -5)

Hệ thống chặn ở **hai lớp**:

1. **Tầng câu lệnh DML:** lệnh `UPDATE` kèm điều kiện kiểm tra giá trị đầu vào. Nếu số lượng không hợp lệ, điều kiện `WHERE` sai, nên **không có dòng nào bị sửa** và dữ liệu cũ giữ nguyên.

   ```sql
   UPDATE CART_ITEMS
   SET Quantity = @new_qty
   WHERE UserID = @user_id
     AND ProductID = @product_id
     AND @new_qty BETWEEN 1 AND 99;
   ```

2. **Tầng CSDL:** nếu một câu lệnh nào đó bỏ qua bước kiểm tra trên, `CHECK (Quantity BETWEEN 1 AND 99)` vẫn từ chối mọi giá trị âm. Đây là lớp bảo vệ cuối cùng, kể cả khi dữ liệu đi vào từ công cụ hay ứng dụng khác.

Nếu khách giảm số lượng về **0**, ứng dụng nên hiểu là "bỏ món này" và gọi lệnh `DELETE` (thao tác 4), thay vì lưu một dòng có số lượng 0.

### Bẫy 2 – Khách bấm "Add to cart" đúng mặt hàng đã có trong giỏ

Hệ thống **cập nhật (cộng dồn) số lượng**, không thêm dòng mới. Lý do:

- Thêm dòng mới sẽ khiến giỏ hiển thị cùng một món hai lần, tính tiền và trừ kho sai.
- Ràng buộc `UNIQUE (UserID, ProductID)` đã chặn dòng trùng, nên một lệnh `INSERT` thường sẽ báo lỗi.

Dùng `INSERT ... ON DUPLICATE KEY UPDATE` để gộp hai trường hợp vào **một câu lệnh nguyên tử**:

- Món chưa có trong giỏ: chèn dòng mới.
- Món đã có trong giỏ (trùng khóa `UNIQUE`): cộng thêm vào số lượng của dòng cũ.

Cách này cũng tránh được lỗi khi khách bấm nút hai lần liên tiếp. Nếu tách thành "SELECT kiểm tra rồi mới INSERT", hai yêu cầu đến cùng lúc có thể cùng thấy "chưa có" và cùng chèn.

## 3. Source Code DML cho 4 thao tác

### 3.1 Add to cart – bỏ một lốc sữa vào giỏ (INSERT)

```sql
INSERT INTO CART_ITEMS (UserID, ProductID, Quantity)
VALUES (@user_id, @product_id, 1) AS new
ON DUPLICATE KEY UPDATE
    Quantity  = CART_ITEMS.Quantity + new.Quantity,
    AddedDate = CURRENT_TIMESTAMP;
```

Nếu tổng số lượng sau khi cộng dồn vượt quá 99, `CHECK` sẽ từ chối lệnh. Với MySQL cũ hơn 8.0.19, thay `new.Quantity` bằng `VALUES(Quantity)` và bỏ `AS new`.

### 3.2 View cart – xem giỏ hàng (SELECT)

```sql
SELECT c.ProductID,
       p.ProductName,
       p.Price,
       c.Quantity,
       p.Price * c.Quantity AS ThanhTien,
       c.AddedDate
FROM CART_ITEMS c
JOIN PRODUCTS p ON p.ProductID = c.ProductID
WHERE c.UserID = @user_id
ORDER BY c.AddedDate DESC;
```

- `WHERE c.UserID = @user_id`: chỉ thấy giỏ hàng của chính mình.
- `JOIN PRODUCTS`: lấy tên và giá **hiện tại** của sản phẩm, nên giỏ hàng luôn hiển thị đúng giá mới nhất.
- Chỉ lấy đúng các cột cần hiển thị, không dùng `SELECT *`.

Tổng tiền giỏ hàng:

```sql
SELECT SUM(p.Price * c.Quantity) AS TongTien
FROM CART_ITEMS c
JOIN PRODUCTS p ON p.ProductID = c.ProductID
WHERE c.UserID = @user_id;
```

### 3.3 Update quantity – đổi từ 1 lốc lên 5 lốc (UPDATE)

```sql
SET @new_qty = 5;

UPDATE CART_ITEMS
SET Quantity = @new_qty
WHERE UserID    = @user_id
  AND ProductID = @product_id
  AND @new_qty BETWEEN 1 AND 99;
```

### 3.4 Remove item – xóa lốc sữa khỏi giỏ (DELETE)

```sql
DELETE FROM CART_ITEMS
WHERE UserID    = @user_id
  AND ProductID = @product_id;
```

## 4. Chốt chặn WHERE: không can thiệp giỏ hàng người khác

| Thao tác | Điều kiện WHERE | Nếu thiếu thì sao? |
|---|---|---|
| View | `UserID = @user_id` | Thiếu: người dùng xem được giỏ hàng của **mọi người** |
| Update | `UserID = @user_id AND ProductID = @product_id` | Thiếu `UserID`: đổi số lượng sữa trong giỏ của **tất cả người dùng**. Thiếu cả hai: đổi mọi dòng trong bảng |
| Delete | `UserID = @user_id AND ProductID = @product_id` | Thiếu `UserID`: xóa sữa khỏi giỏ của **tất cả người dùng**. Thiếu cả hai: xóa sạch bảng |

Chỉ lọc theo `ProductID` là chưa đủ, vì cùng một lốc sữa có thể nằm trong giỏ của hàng nghìn người. Phải **luôn kết hợp `UserID` của người đang đăng nhập**. Không nên lọc theo `CartItemID` do ứng dụng gửi lên mà thiếu `UserID`, vì kẻ xấu có thể đổi mã đó để sửa giỏ hàng của người khác.

## 5. Dò luồng một vòng đời

Ban đầu, giỏ của người dùng 2 có sẵn 2 lốc sữa. Người dùng 1 (`@user_id = 1`) thao tác với lốc sữa (`@product_id = 1`):

| Bước | Lệnh | Giỏ người dùng 1 | Giỏ người dùng 2 |
|---|---|---|---|
| 0 | – | (trống) | Sữa × 2 |
| 1 | Add to cart | Sữa × 1 | Sữa × 2 |
| 1' | Add to cart lần nữa | Sữa × 2 (cộng dồn, không tạo dòng mới) | Sữa × 2 |
| 3 | Update quantity = 5 | Sữa × 5 | Sữa × 2 |
| 3' | Update quantity = -5 | Sữa × 5 (0 dòng bị sửa) | Sữa × 2 |
| 4 | Remove item | (trống) | Sữa × 2 ✅ không bị ảnh hưởng |
