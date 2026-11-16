-- =====================================================
-- Thực hành: Quy trình Quản trị và Truy xuất dữ liệu Task
-- DDL (CREATE) -> DML (INSERT, UPDATE, DELETE) -> DQL (SELECT)
-- =====================================================

CREATE DATABASE IF NOT EXISTS todo_db;
USE todo_db;

DROP TABLE IF EXISTS Task;

-- -----------------------------------------------------
-- Thao tác 1: Khởi tạo bảng Task (DDL)
-- -----------------------------------------------------
CREATE TABLE Task (
    task_id   INT         PRIMARY KEY,
    task_name VARCHAR(50) NOT NULL,
    details   TEXT,
    status    TINYINT(1)  NOT NULL DEFAULT 0,   -- 0 = chưa xong, 1 = đã hoàn thành
    CONSTRAINT chk_task_status CHECK (status IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Thao tác 2: Nạp danh sách công việc (INSERT)
-- -----------------------------------------------------
INSERT INTO Task (task_id, task_name, details, status) VALUES
    (9,  'làm bài tập elearning', 'Làm bài tập session02 - Môn Cơ sở dữ liệu', 1),
    (10, 'Học SQL cơ bản',        'Xem video hướng dẫn về lệnh INSERT và UPDATE', 0);

-- -----------------------------------------------------
-- Thao tác 3: Cập nhật biến động thực tế (UPDATE / DELETE)
-- -----------------------------------------------------
-- Công việc số 10 đã hoàn thành
UPDATE Task
SET status = 1
WHERE task_id = 10;

-- Công việc số 9 không còn cần thiết
DELETE FROM Task
WHERE task_id = 9;

-- -----------------------------------------------------
-- Thao tác 4: Truy xuất báo cáo (SELECT)
-- -----------------------------------------------------
-- 4.1 Hiển thị tất cả thông tin công việc
SELECT * FROM Task;

-- 4.2 Danh sách rút gọn: chỉ task_name và status
SELECT task_name, status
FROM Task;
