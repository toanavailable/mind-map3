-- =====================================================
-- Cỗ máy nhập liệu bị "Kẹt" - Bản sửa lỗi
-- =====================================================

-- 1. Cấu trúc bảng ban đầu
CREATE TABLE SHIPPERS (
    ShipperID   INT PRIMARY KEY AUTO_INCREMENT,
    ShipperName VARCHAR(255),
    Phone       VARCHAR(20)
);

-- -----------------------------------------------------
-- 2. CÁC DÒNG LỆNH LỖI (KHÔNG CHẠY)
-- -----------------------------------------------------
-- Lỗi 1: thiếu dấu nháy đơn đóng sau 'Giao Hàng Nhanh -> Syntax Error
-- INSERT INTO SHIPPERS (ShipperName, Phone)
-- VALUES ('Giao Hàng Nhanh, '0901234567');

-- Lỗi 2: không liệt kê tên cột và thiếu giá trị Phone
-- INSERT INTO SHIPPERS
-- VALUES ('Viettel Post');

-- -----------------------------------------------------
-- 3. CÂU LỆNH INSERT ĐÃ SỬA
-- Số điện thoại Viettel Post là ví dụ, thay bằng số trong hợp đồng
-- -----------------------------------------------------
INSERT INTO SHIPPERS (ShipperName, Phone)
VALUES
    ('Giao Hàng Nhanh', '0901234567'),
    ('Viettel Post',    '19008095');

-- -----------------------------------------------------
-- 4. Phòng ngừa: bắt buộc nhập tên và số điện thoại
-- -----------------------------------------------------
ALTER TABLE SHIPPERS
    MODIFY ShipperName VARCHAR(255) NOT NULL,
    MODIFY Phone       VARCHAR(20)  NOT NULL;

-- Kiểm tra kết quả
SELECT * FROM SHIPPERS;
