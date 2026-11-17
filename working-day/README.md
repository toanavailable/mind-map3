# Quy trình Quản trị và Truy xuất dữ liệu Task (To-do List)

Đóng vai trò Quản trị viên hệ thống cho ứng dụng quản lý công việc cá nhân. Bài làm theo đúng quy trình: **tạo bảng (DDL) → nạp dữ liệu (INSERT) → cập nhật / dọn dẹp (UPDATE, DELETE) → trích xuất báo cáo (SELECT)**.

## Thao tác 1: Khởi tạo bảng Task (DDL)

```sql
CREATE TABLE Task (
    task_id   INT         PRIMARY KEY,
    task_name VARCHAR(50) NOT NULL,
    details   TEXT,
    status    TINYINT(1)  NOT NULL DEFAULT 0,   -- 0 = chưa xong, 1 = đã hoàn thành
    CONSTRAINT chk_task_status CHECK (status IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

| Cột | Kiểu dữ liệu | Ràng buộc | Ghi chú |
|---|---|---|---|
| `task_id` | `INT` | `PRIMARY KEY` | Mã công việc duy nhất |
| `task_name` | `VARCHAR(50)` | `NOT NULL` | Tên công việc, tối đa 50 ký tự |
| `details` | `TEXT` | – | Mô tả chi tiết, có thể dài |
| `status` | `TINYINT(1)` | `NOT NULL`, `DEFAULT 0`, `CHECK (status IN (0, 1))` | 0 = chưa xong, 1 = đã hoàn thành |

Cột `status` dùng `TINYINT(1)` thay cho `BIT`. Trong MySQL, `TINYINT(1)` là cách phổ biến để lưu giá trị đúng/sai (chính là kiểu `BOOLEAN`). Giá trị hiển thị trực tiếp là `0`/`1`, còn `BIT` thường hiển thị dạng nhị phân khó đọc trong các công cụ quản trị. `CHECK` đảm bảo trạng thái chỉ nhận 0 hoặc 1.

## Thao tác 2: Nạp danh sách công việc (INSERT)

```sql
INSERT INTO Task (task_id, task_name, details, status) VALUES
    (9,  'làm bài tập elearning', 'Làm bài tập session02 - Môn Cơ sở dữ liệu', 1),
    (10, 'Học SQL cơ bản',        'Xem video hướng dẫn về lệnh INSERT và UPDATE', 0);
```

- Liệt kê rõ tên cột, để câu lệnh không phụ thuộc thứ tự cột trong bảng.
- `task_name` và `details` là chuỗi nên đặt trong nháy đơn. `task_id` và `status` là số nên không dùng nháy.
- Gộp 2 công việc trong một lệnh `INSERT`.

## Thao tác 3: Cập nhật biến động thực tế (UPDATE / DELETE)

**Cập nhật:** công việc số 10 đã hoàn thành.

```sql
UPDATE Task
SET status = 1
WHERE task_id = 10;
```

**Dọn dẹp:** xóa công việc số 9.

```sql
DELETE FROM Task
WHERE task_id = 9;
```

Cả hai lệnh đều có `WHERE` theo **khóa chính `task_id`**, nên chỉ tác động đúng một công việc. Nếu thiếu `WHERE`, lệnh `UPDATE` sẽ đánh dấu hoàn thành **mọi** công việc, và lệnh `DELETE` sẽ xóa sạch danh sách.

## Thao tác 4: Truy xuất báo cáo (SELECT)

**4.1 Hiển thị tất cả thông tin công việc:**

```sql
SELECT * FROM Task;
```

| task_id | task_name | details | status |
|---|---|---|---|
| 10 | Học SQL cơ bản | Xem video hướng dẫn về lệnh INSERT và UPDATE | 1 |

**4.2 Danh sách rút gọn, chỉ lấy `task_name` và `status`:**

```sql
SELECT task_name, status
FROM Task;
```

| task_name | status |
|---|---|
| Học SQL cơ bản | 1 |

Chỉ chọn đúng 2 cột cần hiển thị thay vì `SELECT *`. Cách này đặc biệt có lợi vì cột `details` (kiểu `TEXT`) có thể rất dài mà giao diện rút gọn lại không cần.

## Self-Check

| Tiêu chí | Đạt |
|---|---|
| Tạo bảng `Task` trước khi `INSERT` | ✅ |
| `UPDATE` và `DELETE` có `WHERE task_id = ...` | ✅ |
| `task_name`, `details` nằm trong nháy đơn `'...'` | ✅ |
| `task_id`, `status` không dùng nháy đơn | ✅ |
| Danh sách rút gọn chỉ chọn 2 cột, không dùng `SELECT *` | ✅ |
