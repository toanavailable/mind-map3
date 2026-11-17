-- =====================================================
-- BÀI TẬP TỔNG HỢP: QUẢN LÝ HỆ THỐNG BÁN HÀNG SHOP THỜI TRANG
-- Quy trình: DDL -> INSERT -> UPDATE/DELETE -> SELECT
-- MySQL 8.0.16+ (CHECK được thực thi từ 8.0.16)
-- =====================================================

CREATE DATABASE IF NOT EXISTS fashion_shop;
USE fashion_shop;

DROP TABLE IF EXISTS products;

-- =====================================================
-- PHẦN 1: THIẾT KẾ BẢNG
-- =====================================================
CREATE TABLE products (
    product_id   CHAR(3)        NOT NULL,
    product_name VARCHAR(100)   NOT NULL,
    size         VARCHAR(5)     NOT NULL,
    price        DECIMAL(12, 2) NOT NULL,
    CONSTRAINT pk_products       PRIMARY KEY (product_id),
    CONSTRAINT chk_products_size  CHECK (size IN ('XS', 'S', 'M', 'L', 'XL', 'XXL')),
    CONSTRAINT chk_products_price CHECK (price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- PHẦN 2: NẠP DỮ LIỆU
-- =====================================================
INSERT INTO products (product_id, product_name, size, price) VALUES
    ('P01', 'Áo sơ mi trắng', 'L',  250000),
    ('P02', 'Quần Jean xanh', 'M',  450000),
    ('P03', 'Áo thun Basic',  'XL', 150000);

-- Dữ liệu lỗi: size NULL và giá âm -> bị ràng buộc từ chối (cố ý để chạy riêng)
-- INSERT INTO products (product_id, product_name, size, price) VALUES
--     ('P04', 'Áo hoodie', NULL, -200000);
-- => Error 1048: Column 'size' cannot be null
-- => (nếu có size) Error 3819: Check constraint 'chk_products_price' is violated

SELECT * FROM products;

-- =====================================================
-- PHẦN 3: THAY ĐỔI TỪ THỰC TẾ
-- =====================================================
-- 3.1 Giảm giá P02 còn 400000
UPDATE products
SET price = 400000
WHERE product_id = 'P02';

-- 3.2 Tăng giá TOÀN BỘ sản phẩm lên 10% (cố ý không có WHERE)
-- Safe Update Mode (mặc định trong MySQL Workbench) sẽ chặn UPDATE không có WHERE theo khóa
SET SQL_SAFE_UPDATES = 0;

UPDATE products
SET price = price * 1.1;

SET SQL_SAFE_UPDATES = 1;

SELECT * FROM products;

-- =====================================================
-- PHẦN 4: XỬ LÝ - XÓA SẢN PHẨM NGỪNG KINH DOANH
-- =====================================================
DELETE FROM products
WHERE product_id = 'P03';

-- =====================================================
-- PHẦN 5: TRUY VẤN PHỤC VỤ KINH DOANH
-- =====================================================
-- 5.1 Xem toàn bộ sản phẩm
SELECT * FROM products;

-- 5.2 In nhãn sản phẩm (chỉ cần Tên, Size)
SELECT product_name, size
FROM products;

-- 5.3 Tìm sản phẩm giá > 300000
SELECT product_id, product_name, size, price
FROM products
WHERE price > 300000;
