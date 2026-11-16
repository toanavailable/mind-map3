-- =====================================================
-- Thảm họa "Đồng giá toàn siêu thị" - Bản sửa lỗi
-- =====================================================

-- 1. Tạo bảng sản phẩm
CREATE TABLE PRODUCTS (
    ProductID     INT PRIMARY KEY,
    ProductName   VARCHAR(100),
    Category      VARCHAR(50),
    OriginalPrice DECIMAL(18, 2)
);

-- 2. Chèn dữ liệu mẫu (gồm cả Điện tử và Thực phẩm)
INSERT INTO PRODUCTS (ProductID, ProductName, Category, OriginalPrice)
VALUES
    (1, 'iPhone 15', 'Electronics', 20000000),
    (2, 'Samsung Refrigerator', 'Electronics', 15000000),
    (3, 'Water Spinach', 'Food', 10000),
    (4, 'Filtered Fresh Milk 4', 'Food', 28000);

-- -----------------------------------------------------
-- 3. ĐOẠN CODE LỖI CỦA THỰC TẬP SINH (KHÔNG CHẠY)
-- Thiếu WHERE -> giảm giá 10% cho TẤT CẢ sản phẩm
-- -----------------------------------------------------
-- UPDATE PRODUCTS
-- SET OriginalPrice = OriginalPrice * 0.9;

-- -----------------------------------------------------
-- 4. CODE ĐÃ SỬA: chỉ giảm giá ngành hàng Electronics
-- -----------------------------------------------------

-- 4.1 Sao lưu trước khi cập nhật
CREATE TABLE PRODUCTS_BACKUP AS
SELECT * FROM PRODUCTS;

-- 4.2 Kiểm tra trước: đúng những sản phẩm sẽ bị ảnh hưởng
SELECT ProductID, ProductName, Category, OriginalPrice,
       OriginalPrice * 0.9 AS GiaSauGiam
FROM PRODUCTS
WHERE Category = 'Electronics';

-- 4.3 Cập nhật trong transaction để có thể hoàn tác
START TRANSACTION;

UPDATE PRODUCTS
SET OriginalPrice = OriginalPrice * 0.9
WHERE Category = 'Electronics';

-- Kiểm tra kết quả: chỉ 2 dòng Electronics thay đổi, Food giữ nguyên
SELECT * FROM PRODUCTS;

COMMIT;      -- Kết quả đúng thì COMMIT
-- ROLLBACK; -- Kết quả sai thì ROLLBACK để hoàn tác
