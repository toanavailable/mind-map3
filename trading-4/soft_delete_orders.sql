-- =====================================================
-- Khủng hoảng "Dọn rác" Đơn hàng cũ
-- Giải pháp được chọn: SOFT DELETE
-- =====================================================

-- 1. Cấu trúc bảng đơn hàng hiện tại
CREATE TABLE ORDERS (
    OrderID      INT PRIMARY KEY AUTO_INCREMENT,
    CustomerName VARCHAR(100),
    OrderDate    DATETIME,
    TotalAmount  DECIMAL(18, 2),
    Status       VARCHAR(20),           -- 'Completed', 'Canceled', 'Pending'
    IsDeleted    TINYINT(1) DEFAULT 0   -- Cờ Soft Delete (0 = hiển thị, 1 = đã ẩn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Dữ liệu thực tế: lẫn đơn hàng thành công và đơn hàng bị hủy
INSERT INTO ORDERS (CustomerName, OrderDate, TotalAmount, Status) VALUES
('Nguyễn Văn A',       '2023-01-10', 500000,  'Completed'),
('Khách hàng vãng lai', '2023-02-15', 1200000, 'Canceled'),   -- "Rác" cần xử lý
('Trần Thị B',          '2023-05-20', 300000,  'Canceled'),   -- "Rác" cần xử lý
('Lê Văn C',            '2024-01-05', 850000,  'Completed');

-- -----------------------------------------------------
-- 3. THỰC THI SOFT DELETE
-- -----------------------------------------------------

-- 3.1 Thêm cột ghi thời điểm ẩn đơn (phục vụ kiểm toán)
ALTER TABLE ORDERS
ADD DeletedAt DATETIME NULL;

-- 3.2 Kiểm tra trước: những đơn sẽ bị đánh dấu
SELECT OrderID, CustomerName, Status
FROM ORDERS
WHERE Status = 'Canceled' AND IsDeleted = 0;

-- 3.3 Đánh dấu ẩn các đơn hủy trong transaction
-- (Với hàng trăm nghìn dòng: thêm LIMIT 10000 và chạy lặp lại đến khi 0 dòng bị ảnh hưởng)
START TRANSACTION;

UPDATE ORDERS
SET IsDeleted = 1,
    DeletedAt = NOW()
WHERE Status = 'Canceled'
  AND IsDeleted = 0;

COMMIT;

-- 3.4 Chỉ mục giúp truy vấn của ứng dụng bán hàng bỏ qua nhanh các đơn đã ẩn
CREATE INDEX idx_orders_isdeleted_orderdate
    ON ORDERS (IsDeleted, OrderDate);

-- -----------------------------------------------------
-- 4. KIỂM TRA KẾT QUẢ
-- -----------------------------------------------------

-- Ứng dụng bán hàng: đơn hủy "biến mất"
SELECT OrderID, CustomerName, OrderDate, TotalAmount, Status
FROM ORDERS
WHERE IsDeleted = 0;

-- Kế toán: đơn hủy vẫn còn để đối soát
SELECT OrderID, CustomerName, OrderDate, TotalAmount, Status, DeletedAt
FROM ORDERS
WHERE Status = 'Canceled';

-- Khôi phục một đơn nếu ẩn nhầm
-- UPDATE ORDERS SET IsDeleted = 0, DeletedAt = NULL WHERE OrderID = 2;
