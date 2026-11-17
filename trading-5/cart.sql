-- =====================================================
-- Module "Giỏ Hàng Điện Tử" (Shopping Cart)
-- MySQL 8.0.19+ (CHECK cần 8.0.16+, cú pháp "AS new" cần 8.0.19+)
-- =====================================================

CREATE DATABASE IF NOT EXISTS shopping_cart_db;
USE shopping_cart_db;

DROP TABLE IF EXISTS CART_ITEMS;
DROP TABLE IF EXISTS PRODUCTS;
DROP TABLE IF EXISTS USERS;

-- -----------------------------------------------------
-- 0. Chuẩn bị bảng và dữ liệu
-- -----------------------------------------------------
CREATE TABLE USERS (
    UserID   INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE PRODUCTS (
    ProductID   INT PRIMARY KEY AUTO_INCREMENT,
    ProductName VARCHAR(100)   NOT NULL,
    Price       DECIMAL(18, 2) NOT NULL CHECK (Price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bảng giỏ hàng theo đề bài
CREATE TABLE CART_ITEMS (
    CartItemID INT PRIMARY KEY AUTO_INCREMENT,
    UserID     INT,
    ProductID  INT,
    Quantity   INT,
    AddedDate  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Gia cố bảng giỏ hàng: lớp bảo vệ cuối cùng ở tầng CSDL
ALTER TABLE CART_ITEMS
    MODIFY UserID    INT NOT NULL,
    MODIFY ProductID INT NOT NULL,
    MODIFY Quantity  INT NOT NULL DEFAULT 1,
    ADD CONSTRAINT uq_cart_user_product UNIQUE (UserID, ProductID),           -- mỗi món chỉ 1 dòng / 1 người
    ADD CONSTRAINT chk_cart_quantity    CHECK (Quantity BETWEEN 1 AND 99),    -- chặn số lượng âm, 0, quá lớn
    ADD CONSTRAINT fk_cart_user    FOREIGN KEY (UserID)    REFERENCES USERS (UserID)       ON DELETE CASCADE,
    ADD CONSTRAINT fk_cart_product FOREIGN KEY (ProductID) REFERENCES PRODUCTS (ProductID);

INSERT INTO USERS (FullName) VALUES ('Nguyễn Văn A'), ('Trần Thị B');

INSERT INTO PRODUCTS (ProductName, Price) VALUES
    ('Lốc sữa TH True Milk 4 hộp', 32000),
    ('Bánh mì sandwich',           25000),
    ('Trứng gà (10 quả)',          35000);

-- Giỏ hàng có sẵn của người dùng khác (dùng để kiểm tra không can thiệp chéo)
INSERT INTO CART_ITEMS (UserID, ProductID, Quantity) VALUES (2, 1, 2);

-- Tham số do ứng dụng truyền vào (người đang đăng nhập và món đang thao tác)
SET @user_id    = 1;   -- Nguyễn Văn A
SET @product_id = 1;   -- Lốc sữa

-- =====================================================
-- 1. ADD TO CART: bỏ 1 lốc sữa vào giỏ
--    Chưa có -> INSERT dòng mới
--    Đã có   -> cộng dồn số lượng vào dòng cũ (không tạo dòng trùng)
-- =====================================================
INSERT INTO CART_ITEMS (UserID, ProductID, Quantity)
VALUES (@user_id, @product_id, 1) AS new
ON DUPLICATE KEY UPDATE
    Quantity  = CART_ITEMS.Quantity + new.Quantity,
    AddedDate = CURRENT_TIMESTAMP;

-- =====================================================
-- 2. VIEW CART: xem giỏ hàng của chính mình
-- =====================================================
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

-- Tổng tiền giỏ hàng
SELECT SUM(p.Price * c.Quantity) AS TongTien
FROM CART_ITEMS c
JOIN PRODUCTS p ON p.ProductID = c.ProductID
WHERE c.UserID = @user_id;

-- =====================================================
-- 3. UPDATE QUANTITY: đổi số lượng sữa từ 1 lên 5 lốc
--    WHERE chốt cả UserID lẫn ProductID -> chỉ sửa đúng món trong giỏ của mình
-- =====================================================
SET @new_qty = 5;

UPDATE CART_ITEMS
SET Quantity = @new_qty
WHERE UserID    = @user_id
  AND ProductID = @product_id
  AND @new_qty BETWEEN 1 AND 99;   -- số lượng không hợp lệ -> không dòng nào bị sửa

-- =====================================================
-- 4. REMOVE ITEM: xóa lốc sữa khỏi giỏ vì đổi ý
--    WHERE chốt cả UserID lẫn ProductID -> không xóa nhầm giỏ người khác
-- =====================================================
DELETE FROM CART_ITEMS
WHERE UserID    = @user_id
  AND ProductID = @product_id;

-- Kiểm tra: giỏ của người dùng 2 vẫn còn nguyên
SELECT * FROM CART_ITEMS;

-- =====================================================
-- KIỂM THỬ BẪY DỮ LIỆU
-- =====================================================
-- Bẫy 1: số lượng âm
-- UPDATE CART_ITEMS SET Quantity = -5 WHERE UserID = 1 AND ProductID = 2;           -- bị CHECK từ chối
-- SET @new_qty = -5;  (chạy lại lệnh UPDATE ở mục 3)                                -- 0 dòng bị sửa
-- INSERT INTO CART_ITEMS (UserID, ProductID, Quantity) VALUES (1, 2, -5);           -- bị CHECK từ chối

-- Bẫy 2: thêm trùng mặt hàng đã có trong giỏ
-- Chạy lệnh ADD TO CART (mục 1) 2 lần liên tiếp -> vẫn chỉ 1 dòng, Quantity = 2
-- INSERT INTO CART_ITEMS (UserID, ProductID, Quantity) VALUES (2, 1, 1);            -- INSERT thường bị UNIQUE từ chối
