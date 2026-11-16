# Cỗ máy nhập liệu bị "Kẹt"

Phân tích 2 lỗi trong các câu lệnh `INSERT` khi thêm hai đối tác vận chuyển "Giao Hàng Nhanh" và "Viettel Post" vào bảng `SHIPPERS`, rồi viết lại câu lệnh hoàn chỉnh.

## 1. Cấu trúc bảng

```sql
CREATE TABLE SHIPPERS (
    ShipperID   INT PRIMARY KEY AUTO_INCREMENT,
    ShipperName VARCHAR(255),
    Phone       VARCHAR(20)
);
```

Bảng có **3 cột**. `ShipperID` tự tăng nên không cần nhập. `ShipperName` và `Phone` chưa có ràng buộc `NOT NULL`.

## 2. Phân tích lỗi

### Lỗi 1 – Thiếu dấu nháy đơn đóng (Syntax Error)

```sql
INSERT INTO SHIPPERS (ShipperName, Phone)
VALUES ('Giao Hàng Nhanh, '0901234567');
```

- Chuỗi `'Giao Hàng Nhanh` **thiếu dấu nháy đơn đóng** ngay sau chữ "Nhanh".
- MySQL đọc từ dấu `'` mở đầu tới dấu `'` kế tiếp, nên hiểu chuỗi là `'Giao Hàng Nhanh, '`. Phần còn lại là `0901234567');`, tức một con số đứng ngay sau chuỗi mà không có dấu phẩy ngăn cách, kèm một dấu `'` mở mà không bao giờ được đóng.
- Câu lệnh sai cấu trúc nên MySQL báo **Syntax Error** và từ chối lưu.

**Cách sửa:** đóng nháy cho từng giá trị chuỗi: `('Giao Hàng Nhanh', '0901234567')`.

### Lỗi 2 – Không liệt kê tên cột và thiếu giá trị Phone (dữ liệu bị "Kẹt")

```sql
INSERT INTO SHIPPERS
VALUES ('Viettel Post');
```

- Câu lệnh **không ghi danh sách cột**, nên MySQL hiểu là đang truyền giá trị cho **tất cả 3 cột theo đúng thứ tự** `(ShipperID, ShipperName, Phone)`, nhưng chỉ nhận được 1 giá trị.
- Câu lệnh cũng **hoàn toàn thiếu số điện thoại**. Vì cột `Phone` không có `NOT NULL`, nên ở những công cụ hay chế độ chấp nhận câu lệnh này, cột `Phone` không được truyền giá trị sẽ nhận `NULL`. Bản ghi được lưu nhưng thiếu thông tin liên hệ, tức dữ liệu bị "kẹt".
- Thứ tự giá trị cũng không khớp: giá trị đầu tiên sẽ rơi vào cột `ShipperID` chứ không phải `ShipperName`.

> Lưu ý: với MySQL 8 ở chế độ mặc định, câu lệnh này thực tế bị từ chối với lỗi `Column count doesn't match value count at row 1` (mã 1136), vì số giá trị không khớp số cột. Dù bị chấp nhận (dữ liệu thiếu) hay bị từ chối, nguyên nhân gốc vẫn là: **không liệt kê tên cột và không truyền đủ giá trị**.

## 3. Câu lệnh INSERT hoàn chỉnh

```sql
INSERT INTO SHIPPERS (ShipperName, Phone)
VALUES
    ('Giao Hàng Nhanh', '0901234567'),
    ('Viettel Post',    '19008095');
```

- **Liệt kê rõ tên cột** `(ShipperName, Phone)`. Câu lệnh không phụ thuộc thứ tự cột trong bảng và không bị hỏng khi bảng được `ALTER` sau này.
- **Bỏ qua `ShipperID`** vì MySQL tự sinh bằng `AUTO_INCREMENT`.
- **Mọi chuỗi đều được đóng nháy đơn đầy đủ**, kể cả số điện thoại (kiểu chuỗi để giữ số 0 ở đầu).
- **Gộp 2 dòng trong một lệnh `INSERT`**, nên nhanh và gọn hơn.
- Số điện thoại của Viettel Post ở đây chỉ là ví dụ, cần thay bằng số trong hợp đồng.

Kết quả:

| ShipperID | ShipperName | Phone |
|---|---|---|
| 1 | Giao Hàng Nhanh | 0901234567 |
| 2 | Viettel Post | 19008095 |

## 4. Phòng ngừa

Để công cụ nhập liệu không thể lưu đối tác thiếu tên hoặc thiếu số điện thoại, thêm ràng buộc `NOT NULL`:

```sql
ALTER TABLE SHIPPERS
    MODIFY ShipperName VARCHAR(255) NOT NULL,
    MODIFY Phone       VARCHAR(20)  NOT NULL;
```

Bài học rút ra:

- Luôn kiểm tra cặp dấu nháy đơn của từng giá trị chuỗi.
- Luôn liệt kê tên cột trong `INSERT INTO`.
- Dùng `NOT NULL` cho các thông tin bắt buộc, để CSDL chặn dữ liệu thiếu ngay từ đầu.
