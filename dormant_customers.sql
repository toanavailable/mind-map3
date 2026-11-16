-- =====================================================
-- Trích xuất Dữ liệu Khách hàng "Ngủ đông"
-- =====================================================

-- 1. Tạo bảng khách hàng (mô phỏng bảng lớn)
CREATE TABLE CUSTOMERS (
    CustomerID       INT PRIMARY KEY AUTO_INCREMENT,
    FullName         VARCHAR(100),
    Email            VARCHAR(100),
    City             VARCHAR(50),
    LastPurchaseDate DATE,          -- Ngày mua hàng cuối cùng
    Status           VARCHAR(20),   -- Trạng thái tài khoản (Active, Locked...)
    Gender           VARCHAR(10),
    DateOfBirth      DATE,
    Points           INT,
    Address          VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Dữ liệu mẫu với các "Bẫy dữ liệu"
INSERT INTO CUSTOMERS (FullName, Email, City, LastPurchaseDate, Status) VALUES
('Nguyễn Văn A', 'anv@gmail.com', 'Hà Nội', '2025-05-20', 'Active'),  -- Khách tiềm năng (hơn 6 tháng)
('Trần Thị B',   'btt@gmail.com', 'Hà Nội', '2026-02-10', 'Active'),  -- Mới mua (loại)
('Lê Văn C',     NULL,            'Hà Nội', '2025-01-15', 'Active'),  -- Lỗi: Không có Email
('Phạm Minh D',  'dpm@gmail.com', 'Hà Nội', '2024-12-01', 'Locked'),  -- Lỗi: Tài khoản bị khóa
('Hoàng An E',   'eha@gmail.com', 'TP HCM', '2025-03-01', 'Active');  -- Lỗi: Sai thành phố

-- -----------------------------------------------------
-- 3. Câu lệnh trích xuất khách hàng "ngủ đông"
-- Mốc: 01/04/2026, lùi 6 tháng -> trước ngày 01/10/2025
-- -----------------------------------------------------
SELECT FullName, Email
FROM CUSTOMERS
WHERE City = 'Hà Nội'
  AND LastPurchaseDate < DATE_SUB('2026-04-01', INTERVAL 6 MONTH)  -- < '2025-10-01'
  AND Email IS NOT NULL
  AND TRIM(Email) <> ''
  AND Status = 'Active';

-- Kết quả mong đợi: 1 dòng
-- | FullName     | Email         |
-- | Nguyễn Văn A | anv@gmail.com |

-- -----------------------------------------------------
-- 4. (Tối ưu cho bảng hàng triệu dòng) Chỉ mục hỗ trợ truy vấn
-- -----------------------------------------------------
CREATE INDEX idx_customers_city_status_lastpurchase
    ON CUSTOMERS (City, Status, LastPurchaseDate);
