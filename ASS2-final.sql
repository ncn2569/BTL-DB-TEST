    -----------------------------------------------------------
-- REGION 1: TẠO BẢNG & INSERT DỮ LIỆU MẪU
-----------------------------------------------------------

-- Xóa các bảng con trước, bảng cha sau để tránh lỗi khóa ngoại
IF OBJECT_ID('DELIVERING', 'U') IS NOT NULL DROP TABLE DELIVERING;
IF OBJECT_ID('RATING', 'U') IS NOT NULL DROP TABLE RATING;
IF OBJECT_ID('FOOD_ORDERED', 'U') IS NOT NULL DROP TABLE FOOD_ORDERED;
IF OBJECT_ID('VOUCHER', 'U') IS NOT NULL DROP TABLE VOUCHER;
IF OBJECT_ID('PARENT_RESTAURANT', 'U') IS NOT NULL DROP TABLE PARENT_RESTAURANT;
IF OBJECT_ID('FOOD_BELONG', 'U') IS NOT NULL DROP TABLE FOOD_BELONG;

-- Xóa các bảng trung gian / chính
IF OBJECT_ID('ORDERS', 'U') IS NOT NULL DROP TABLE ORDERS;
IF OBJECT_ID('FOOD', 'U') IS NOT NULL DROP TABLE FOOD;
IF OBJECT_ID('RESTAURANT', 'U') IS NOT NULL DROP TABLE RESTAURANT;
IF OBJECT_ID('CUSTOMER', 'U') IS NOT NULL DROP TABLE CUSTOMER;
IF OBJECT_ID('SHIPPER', 'U') IS NOT NULL DROP TABLE SHIPPER;
IF OBJECT_ID('ADMIN', 'U') IS NOT NULL DROP TABLE ADMIN;

-- Xóa bảng gốc USERS
IF OBJECT_ID('USERS', 'U') IS NOT NULL DROP TABLE USERS;
GO

-- Bảng USERS: lưu thông tin tài khoản chung của tất cả loại người dùng
CREATE TABLE USERS (
    ID INT PRIMARY KEY,
    
    Ho_ten NVarChar(40) NOT NULL,
    -- Họ tên gồm chữ cái (có dấu) và khoảng trắng
    Check (Ho_ten NOT LIKE '%[^A-Za-zÀ-ỹ ]%'),
   
    Email VARCHAR(320) NOT NULL UNIQUE,
    -- Định dạng email: có @ và dấu chấm sau @
    CHECK (email LIKE '%_@_%._%'),

    SDT VARCHAR(10) NOT NULL,
    -- Số điện thoại: 10 chữ số, bắt đầu bằng 0
    CHECK (SDT LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),

    Password VarChar(100) NOT NULL,
    -- Mật khẩu: >= 8 ký tự, chứa chữ cái, chữ số, ký tự đặc biệt
    CHECK ( LEN(Password) >= 8 AND
            PATINDEX('%[A-Za-z]%', Password) > 0 AND
            PATINDEX('%[0-9]%', Password) > 0 AND
            PATINDEX('%[^A-Za-z0-9]%', Password) > 0),

    TKNH VARCHAR(20) NOT NULL,
    -- Tài khoản ngân hàng: chỉ số, dài 10–16 ký tự
    CHECK (TKNH NOT LIKE '%[^0-9]%' AND LEN(TKNH) BETWEEN 10 AND 16),

    Dia_chi NVarchar(255) NOT NULL,

    vai_tro Varchar(10) NOT NULL,
    CHECK (vai_tro IN ('RESTAURANT','SHIPPER','CUSTOMER','ADMIN'))
);

-- Bảng RESTAURANT: mở rộng USERS thành nhà hàng, có giờ mở cửa / đóng cửa, trạng thái
CREATE TABLE RESTAURANT(

    user_ID INT PRIMARY KEY,

    Foreign key (user_ID) References USERS(ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

    
    Thoi_gian_mo_cua   TIME(0) NOT NULL,  -- TIME(0) = HH:MM:SS, không phần thập phân giây
    Thoi_gian_dong_cua TIME(0) NOT NULL,

    -- giờ mở cửa < giờ đóng cửa
    CHECK (Thoi_gian_mo_cua < Thoi_gian_dong_cua),
    Trang_thai NVARCHAR(14) NOT NULL,
    -- Trạng thái nhà hàng: đang hoạt động / tạm nghỉ / đóng cửa
    CHECK (Trang_thai IN (N'đang hoạt động', N'tạm nghỉ', N'đóng cửa'))
);

-- Bảng CUSTOMER: ánh xạ USERS thành khách hàng
CREATE TABLE CUSTOMER(
    user_ID INT PRIMARY KEY,

    Foreign key (user_ID) References USERS(ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- Bảng SHIPPER: ánh xạ USERS thành shipper, thêm biển số, điểm, trạng thái
CREATE TABLE SHIPPER(
    user_ID INT PRIMARY KEY,

    Foreign key (user_ID) References USERS(ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

    bien_so_xe Varchar(11) UNIQUE, 
    -- Biển số xe: 2 số - 1 hoặc 2 chữ cái - 5 số (dạng chung)
    CHECK (Bien_so_xe LIKE '[0-9][0-9]-[A-Z][0-9]-[0-9][0-9][0-9][0-9][0-9]%' OR 
           Bien_so_xe LIKE '[0-9][0-9]-[A-Z][A-Z]-[0-9][0-9][0-9][0-9][0-9]%' ),

    trang_thai NVARCHAR(11) NOT NULL,
    -- Trạng thái shipper: trực tuyến / ngoại tuyến / đang bận
    CHECK (trang_thai IN (N'trực tuyến', N'ngoại tuyến', N'đang bận'))
);
-- Bảng ADMIN: ánh xạ USERS thành admin hệ thống
CREATE TABLE ADMIN (
    user_ID INT PRIMARY KEY,
    FOREIGN KEY (user_ID) REFERENCES USERS(ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    quyen_han NVARCHAR(255) NOT NULL

);
-- Bảng ORDERS: thông tin đơn hàng
CREATE TABLE ORDERS (
    -- order_ID: khóa chính đơn hàng

    order_ID        INT PRIMARY KEY,
    restaurant_ID   INT NOT NULL,
    customer_ID     INT NOT NULL,

    ngay_tao        DATETIME DEFAULT CURRENT_TIMESTAMP,

    ghi_chu         NVARCHAR(MAX),
    dia_chi         NVARCHAR(255),

    gia_don_hang    DECIMAL(10, 2) NOT NULL CHECK (gia_don_hang > 0), -- Tổng giá trị món, > 0

    phi_giao_hang   DECIMAL(10, 2) NOT NULL CHECK (phi_giao_hang >= 0),-- Phí giao hàng, >= 0

    trang_thai      NVARCHAR(50) NOT NULL ,
    -- Trạng thái đơn: đang xử lý / đang giao / hoàn tất / hủy
    CHECK ( trang_thai IN (N'đang xử lý', N'đang giao',N'hoàn tất', N'hủy')),

    FOREIGN KEY (restaurant_ID) REFERENCES RESTAURANT(user_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (customer_ID) REFERENCES CUSTOMER(user_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
-- Bảng FOOD: danh mục món ăn
CREATE TABLE FOOD (
    food_ID INT PRIMARY KEY,

    gia     DECIMAL (10,2) NOT NULL CHECK (gia > 0),-- Giá món > 0

    ten     NVARCHAR(255) NOT NULL, 
    mo_ta   NVARCHAR (255),
    
    trang_thai  NVARCHAR(50) NOT NULL,
    check (trang_thai IN (N'còn hàng', N'hết hàng')),-- Trạng thái còn / hết

    anh VARCHAR(4000) NOT NULL, -- Link ảnh món ăn

	Diem_danh_gia DECIMAL (10,2) NOT NULL 
	-- Điểm đánh giá [1;5]
	CHECK (Diem_danh_gia BETWEEN 1 AND 5)
);
-- Bảng RATING: đánh giá đơn hàng (1 đơn có thể nhiều rating_id nếu cần)
CREATE TABLE RATING (
    order_ID INT,
    rating_ID INT,
    food_ID INT, 
    Noi_dung NVARCHAR (255),
    Diem_danh_gia INT NOT NULL CHECK (Diem_danh_gia BETWEEN 1 AND 5),-- Điểm [1;5]
    Ngay_danh_gia  DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(order_ID, rating_ID),
    FOREIGN KEY(order_ID) REFERENCES ORDERS(order_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY(food_ID) REFERENCES FOOD(food_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- Bảng DELIVERING: ánh xạ đơn hàng với shipper đang giao
CREATE TABLE DELIVERING(
    shipper_ID INT NOT NULL,
    FOREIGN KEY (shipper_ID) REFERENCES SHIPPER(user_ID) 
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
    order_ID INT PRIMARY KEY,
    FOREIGN KEY (order_ID) REFERENCES ORDERS(order_ID) 
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- Bảng PARENT_RESTAURANT: quan hệ cha–con giữa các nhà hàng
CREATE TABLE PARENT_RESTAURANT (
    parent_id INT NOT NULL,
    child_id  INT NOT NULL,

    PRIMARY KEY (parent_id, child_id),
    UNIQUE (child_id),  -- 1 nhà hàng con chỉ có 1 nhà hàng cha

    FOREIGN KEY (parent_id) REFERENCES RESTAURANT(user_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    FOREIGN KEY (child_id) REFERENCES RESTAURANT(user_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CHECK (parent_id <> child_id)
);

-- Bảng VOUCHER: quản lý voucher và đơn hàng áp dụng
CREATE TABLE VOUCHER (
    voucher_ID INT PRIMARY KEY,

    han_su_dung DATETIME NOT NULL, -- bỏ check vì quá cứng nhắc và có trigger để check

    mo_ta   NVARCHAR(255),

    dieu_kien_su_dung NVARCHAR(255) NOT NULL,

    gia_tri_su_dung INT NOT NULL CHECK ( gia_tri_su_dung BETWEEN 1 AND 100),-- % giảm [1;100]

    order_ID INT,
    customer_ID INT,
    FOREIGN KEY (order_ID) REFERENCES ORDERS(order_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (customer_ID) REFERENCES CUSTOMER(user_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
    
);

-- Bảng FOOD_ORDERED: chi tiết món ăn của từng đơn
CREATE TABLE FOOD_ORDERED (
    food_ID int,
    order_ID int,
    PRIMARY KEY (food_ID, order_ID),
    FOREIGN KEY (food_ID) REFERENCES FOOD(food_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (order_ID) REFERENCES ORDERS(order_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- Bảng FOOD_BELONG: món ăn thuộc nhà hàng nào
CREATE TABLE FOOD_BELONG (
    food_ID int,
    restaurant_ID int,
    PRIMARY KEY (food_ID, restaurant_ID),
    FOREIGN KEY (food_ID) REFERENCES FOOD(food_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (restaurant_ID) REFERENCES RESTAURANT(user_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


GO

-----------------------------------------------------------
-- REGION 2: TRIGGER CỦA BẢNG 
-----------------------------------------------------------

-- ORDERS: chỉ cho phép tạo/cập nhật đơn cho nhà hàng đang hoạt động
CREATE TRIGGER trg_CheckRestaurantStatusBeforeOrder
ON ORDERS
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN RESTAURANT r ON i.restaurant_ID = r.user_ID
        WHERE r.Trang_thai <> N'đang hoạt động'
    )
    BEGIN
        RAISERROR (N'Nhà hàng không ở trạng thái hoạt động, không thể tạo đơn!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- PARENT_RESTAURANT: không cho nhà hàng con lại quản lý nhà hàng khác
CREATE TRIGGER trg_CheckRestaurantManagementLogic
ON PARENT_RESTAURANT
FOR INSERT, UPDATE 
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(
        SELECT 1
        FROM inserted i
        JOIN PARENT_RESTAURANT p ON i.child_id = p.parent_id
    )
    BEGIN
        RAISERROR (N'Nhà hàng con không thể quản lý nhà hàng khác.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ORDERS: đơn chuyển sang 'đang giao' phải có ít nhất 1 món trong FOOD_ORDERED
CREATE TRIGGER trg_Order_have_1_food
ON ORDERS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN DELETED d ON i.order_ID = d.order_ID
        WHERE 
            i.trang_thai = N'đang giao' 
            AND NOT EXISTS (                     
                SELECT 1
                FROM FOOD_ORDERED fo
                WHERE fo.order_ID = i.order_ID
            )
    )
    BEGIN
        RAISERROR (N'Đơn hàng được giao phải bao gồm ít nhất một món ăn.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ORDERS: kiểm soát luồng chuyển trạng thái hợp lệ (đang xử lý -> đang giao/hủy, đang giao -> hoàn tất)
CREATE TRIGGER trg_order_trang_thai_logic
ON ORDERS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM INSERTED i 
        JOIN DELETED d ON i.order_ID=d.order_ID
        WHERE i.trang_thai<>d.trang_thai
        AND(
            d.trang_thai IN (N'hoàn tất',N'hủy') -- Hoàn tất / hủy không được đổi trạng thái
            OR (
                -- Đang xử lý chỉ có thể -> đang giao, hủy; đang giao chỉ có thể -> hoàn tất
                NOT( 
                    (d.trang_thai = N'đang xử lý' AND i.trang_thai IN (N'đang giao', N'hủy')) OR
                    (d.trang_thai = N'đang giao' AND i.trang_thai = N'hoàn tất')
                )
            )
        )
    )
    BEGIN
        RAISERROR (N'Trạng thái đơn hàng thay đổi không hợp lệ', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;

-- RATING: ngày đánh giá phải >= ngày tạo đơn
GO
CREATE TRIGGER trg_rating_date
ON RATING 
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN ORDERS o ON i.order_ID=o.order_ID
        WHERE i.Ngay_danh_gia<o.ngay_tao
    )
    BEGIN 
        RAISERROR (N'Ngày đánh giá phải sau ngày tạo đơn hàng.', 16, 1); -- sau ngày tạo đơn vì get date lấy đầu ngày
        ROLLBACK TRANSACTION;
        RETURN; 
    END
END;
GO

-- RATING: chỉ đánh giá khi đơn hoàn tất
CREATE TRIGGER trg_rating_logic
ON RATING 
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN ORDERS o ON i.order_ID=o.order_ID
        WHERE o.trang_thai <> N'hoàn tất'
    )
    BEGIN 
        RAISERROR (N'Chỉ được đánh giá đơn hàng khi ở trạng thái hoàn tất.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN; 
    END
    IF EXISTS (
        SELECT order_ID
        FROM RATING
        GROUP BY order_ID
        HAVING COUNT(*) > 1
    )
    BEGIN 
        RAISERROR (N'Mỗi đơn hàng chỉ được đánh giá 1 lần.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN; 
    END
END;

-------------------------
-- TRIGGER TRÊN CÁC BẢNG KHÁC
-------------------------

-- DELIVERING: shipper phải "trực tuyến" mới nhận đơn, nhận xong đổi sang "đang bận"
CREATE TRIGGER trg_checkShipperStatusBeforeDelivering
ON DELIVERING
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN SHIPPER r ON i.shipper_ID = r.user_ID
        WHERE r.trang_thai <> N'trực tuyến'
    )
    BEGIN
        RAISERROR (N'Shipper đang không trực tuyến không thể nhận đơn!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    -- Nếu hợp lệ thì cập nhật trạng thái shipper sang "đang bận"
    UPDATE s
    SET s.trang_thai = N'đang bận'
    FROM SHIPPER s
    JOIN inserted i ON s.user_ID = i.shipper_ID;
END;
GO

CREATE TRIGGER trg_checkShipperStatusAfterDelivering
ON ORDERS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.trang_thai = N'trực tuyến'
    FROM SHIPPER s
    JOIN DELIVERING d ON s.user_ID = d.shipper_ID
    JOIN inserted i   ON i.order_ID = d.order_ID
    JOIN deleted  old ON old.order_ID = i.order_ID
    WHERE i.trang_thai   = N'hoàn tất'
      AND s.trang_thai   = N'đang bận';
END;
GO


-- FOOD_ORDERED: chỉ cho phép thêm món đang "còn hàng"
CREATE TRIGGER trg_checkFoodStatusBefortOrder
ON FOOD_ORDERED
AFTER INSERT, UPDATE 
AS
BEGIN   
    SET NOCOUNT ON
        IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN FOOD r ON i.food_ID = r.food_ID
        WHERE r.trang_thai <> N'còn hàng'
    )
    BEGIN
        RAISERROR (N'Món ăn đang hết hàng, không thể thêm', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- VOUCHER: không cho áp dụng voucher cho đơn có ngày tạo > hạn sử dụng
CREATE TRIGGER trg_CheckVoucherOrderDate
ON VOUCHER
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN ORDERS o ON o.order_ID = i.order_ID
        WHERE i.order_ID IS NOT NULL
          AND o.ngay_tao > i.han_su_dung
    )
    BEGIN
        RAISERROR(N'Voucher đã hết hạn, không thể áp dụng cho đơn hàng này.',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-----------------------------------------------------------
-- REGION 3: DỮ LIỆU MẪU BAN ĐẦU (dữ liệu tạm chờ thêm vào sau)
-----------------------------------------------------------
INSERT INTO USERS (ID, Ho_ten, Email, SDT, Password, TKNH, Dia_chi, vai_tro) VALUES
-- ADMIN (1–10)
(1,  N'Nguyễn Văn A', 'admin1@system.com', '0901111111', 'Adm@1234', '111111111111', N'Hà Nội', 'ADMIN'),
(2,  N'Lê Thị B', 'admin2@system.com', '0902222222', 'Adm@1234', '222222222222', N'Hồ Chí Minh', 'ADMIN'),
(3,  N'Phạm Văn C', 'admin3@system.com', '0903333333', 'Adm@1234', '333333333333', N'Đà Nẵng', 'ADMIN'),
(4,  N'Hoàng Thị D', 'admin4@system.com', '0904444444', 'Adm@1234', '444444444444', N'Cần Thơ', 'ADMIN'),
(5,  N'Ngô Thị E', 'admin5@system.com', '0905555555', 'Adm@1234', '555555555555', N'Hải Phòng', 'ADMIN'),

-- CUSTOMER (100–199)
(101, N'Lê Minh Hùng', 'c101@email.com', '0901010101', 'Cus@1234', '101101101101', N'Quận 1, TP.HCM', 'CUSTOMER'),
(102, N'Nguyễn Thị Trang', 'c102@email.com', '0902020202', 'Cus@1234', '102102102102', N'Quận 5, TP.HCM', 'CUSTOMER'),
(103, N'Phạm Quốc Thái', 'c103@email.com', '0903030303', 'Cus@1234', '103103103103', N'Hà Nội', 'CUSTOMER'),
(104, N'Vũ Thị Hoa', 'c104@email.com', '0904040404', 'Cus@1234', '104104104104', N'Cần Thơ', 'CUSTOMER'),
(105, N'Bùi Văn Lâm', 'c105@email.com', '0905050505', 'Cus@1234', '105105105105', N'Đà Nẵng', 'CUSTOMER'),

-- RESTAURANT (200–299)
(201, N'Hủ Tiếu Thanh Xuân', 'r201@restaurant.com', '0902100210', 'Res@1234', '201201201201', N'Quận 1, TP.HCM', 'RESTAURANT'),
(202, N'Cơm Tấm Ba Ghiền', 'r202@restaurant.com', '0902200220', 'Res@1234', '202202202202', N'Đà Nẵng', 'RESTAURANT'),
(203, N'Phở Huỳnh Mai', 'r203@restaurant.com', '0902300230', 'Res@1234', '203203203203', N'Huế', 'RESTAURANT'),
(204, N'Lẩu Bò Bà Sáu', 'r204@restaurant.com', '0902400240', 'Res@1234', '204204204204', N'Cần Thơ', 'RESTAURANT'),
(205, N'Phúc Long', 'r205@restaurant.com', '0902500250', 'Res@1234', '205205205205', N'Hà Nội', 'RESTAURANT'),

-- SHIPPER (300–399)
(301, N'Tài Xế Minh', 's301@shipper.com', '0903100310', 'Shi@1234', '301301301301', N'Hà Nội', 'SHIPPER'),
(302, N'Tài Xế Nam', 's302@shipper.com', '0903200320', 'Shi@1234', '302302302302', N'TP.HCM', 'SHIPPER'),
(303, N'Tài Xế Linh', 's303@shipper.com', '0903300330', 'Shi@1234', '303303303303', N'Cần Thơ', 'SHIPPER'),
(304, N'Tài Xế Hưng', 's304@shipper.com', '0903400340', 'Shi@1234', '304304304304', N'Đà Nẵng', 'SHIPPER'),
(305, N'Tài Xế Phát', 's305@shipper.com', '0903500350', 'Shi@1234', '305305305305', N'Huế', 'SHIPPER');
INSERT INTO RESTAURANT (user_ID, Thoi_gian_mo_cua, Thoi_gian_dong_cua, Trang_thai) VALUES
(201, '08:00', '22:00', N'đang hoạt động'),
(202, '07:00', '21:00', N'tạm nghỉ'),
(203, '09:00', '21:00', N'đang hoạt động'),
(204, '10:00', '23:00', N'đang hoạt động'),
(205, '06:30', '20:30', N'đang hoạt động');
INSERT INTO CUSTOMER (user_ID) VALUES
(3),
(4);

-- SHIPPER: shipper mẫu
INSERT INTO SHIPPER (user_ID, bien_so_xe, diem_danh_gia, trang_thai) VALUES
(6, '29-A1-12345', 4.5, N'trực tuyến');

-- FOOD: danh sách món ăn
INSERT INTO FOOD (food_ID, gia, ten, mo_ta, trang_thai, anh) VALUES
(10, 30000, N'Bánh mì thịt', N'Bánh mì Việt Nam', N'còn hàng', 'banhmi.jpg'),
(11, 45000, N'Phở bò', N'Phở truyền thống', N'còn hàng', 'pho.jpg'),
(12, 25000, N'Trà đá', N'Nước giải khát', N'còn hàng', 'trada.jpg');

-- FOOD_BELONG: món ăn thuộc nhà hàng nào
INSERT INTO FOOD_BELONG VALUES
(10, 1),
(11, 1),
(12, 1),
(10, 5);

-- ORDERS: dữ liệu đơn hàng
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang)
VALUES
(100, 1, 3, N'đang xử lý', N'Không cay', N'Hà Nội', 75000, 15000),
(101, 1, 4, N'hoàn tất', NULL, N'Hồ Chí Minh', 45000, 10000);

-- FOOD_ORDERED: món trong từng đơn
INSERT INTO FOOD_ORDERED VALUES
(10, 100),
(11, 100),
(12, 101);

-- DELIVERING: đơn đang được shipper giao
INSERT INTO DELIVERING (shipper_ID, order_ID)
VALUES
(6, 100);

-- RATING: đánh giá cho đơn
INSERT INTO RATING (order_ID, rating_ID, Noi_dung, Diem_danh_gia)
VALUES
(101, 1, N'Ngon và nhanh', 5);

-- RATING_FOOD: đánh giá món theo đơn
INSERT INTO RATING_FOOD (order_ID, rating_ID, food_ID)
VALUES
(101, 1, 12);

-- PARENT_RESTAURANT: quan hệ nhà hàng cha–con
INSERT INTO PARENT_RESTAURANT (parent_id, child_id)
VALUES
(1, 5);

-- VOUCHER: dữ liệu voucher mẫu
INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
VALUES
(200, '2026-01-01', N'Giảm 30%', N'Đơn tối thiểu 50k', 30, 101, 4);

-----------------------------------------------------------
-- REGION 4: TRIGGER NGHIỆP VỤ 
-----------------------------------------------------------

-- Trigger 1: Hoàn tiền Voucher khi đơn bị hủy --
/*
Nghiệp vụ: 
Nếu đơn có sử dụng voucher, và đơn bị hủy (OrderStatus đổi sang "CANCELED"), 
thì hệ thống phải tự động trả lại (refund) phần giá trị voucher đã trừ trước đó, 
nhưng chỉ khi voucher vẫn còn hiệu lực (not expired).

Ràng buộc:
- Orders.VoucherID NOT NULL

- Orders.Status chuyển từ ≠ “CANCELED” sang “CANCELED”

- Voucher chưa hết hạn tại thời điểm hủy

- RefundAmount = Min(UsedValue, Voucher.MaxValue)

- Thực hiện hoàn vào bảng VoucherUsageLog hoặc cập nhật Voucher.RemainingValue
*/

IF OBJECT_ID('trg_refund_voucher_on_cancel', 'TR') IS NOT NULL
    DROP TRIGGER trg_refund_voucher_on_cancel;
GO

CREATE TRIGGER trg_refund_voucher_on_cancel
ON ORDERS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem có đơn hàng nào vừa chuyển sang trạng thái 'hủy' không
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.order_ID = d.order_ID
        WHERE i.trang_thai = N'hủy'       -- Trạng thái mới là Hủy
          AND d.trang_thai <> N'hủy'      -- Trạng thái cũ chưa Hủy
    )
    BEGIN
        -- Logic: Tìm các Voucher đang gắn với đơn hàng bị hủy
        -- Chỉ hoàn lại (set order_ID = NULL) NẾU Voucher đó VẪN CÒN HẠN sử dụng.
        
        UPDATE VOUCHER
        SET order_ID = NULL
        FROM VOUCHER v
        JOIN inserted i ON v.order_ID = i.order_ID
        WHERE i.trang_thai = N'hủy'
          AND v.han_su_dung >= GETDATE(); -- Quan trọng: Chỉ hoàn nếu hạn sử dụng >= thời điểm hiện tại
    END
END;
GO

-- trigger 2: cập nhật điểm raitng được food khi có sự thay đổi ở rating

IF OBJECT_ID('trg_UpdateFoodRating', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateFoodRating;
GO

CREATE TRIGGER trg_UpdateFoodRating
ON RATING
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.diem_danh_gia = (
        SELECT AVG(CAST(r.Diem_danh_gia AS DECIMAL(3,1)))
        FROM RATING r
        JOIN DELIVERING d ON r.order_ID = d.order_ID
        WHERE d.shipper_ID = s.user_ID
    )
    FROM SHIPPER s
    WHERE s.user_ID IN (
        SELECT d.shipper_ID 
        FROM inserted i
        JOIN DELIVERING d ON i.order_ID = d.order_ID
    );
END;
GO
-----------------------------------
---- TEST MỘT SỐ TRIGGER NGHIỆP VỤ
-----------------------------------
-- Giả sử đơn có 101 voucher
SELECT * FROM VOUCHER WHERE order_ID = 101;

-- set trạng thái hủy
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 101;

-- Kiểm tra Voucher sau khi hủy đơn
SELECT * FROM VOUCHER WHERE voucher_ID = 200;

---------------------------------------------------

-- Test: thêm rating mới cho đơn 100 (do shipper 6 giao) -> điểm shipper cập nhật
SELECT * FROM SHIPPER;
SELECT * FROM RATING;
INSERT INTO RATING(order_ID, rating_ID, Noi_dung, Diem_danh_gia)
VALUES (100, 2, N'Thái độ tốt', 4);
INSERT INTO RATING(order_ID, rating_ID, Noi_dung, Diem_danh_gia)
VALUES (100, 3, N'Thái độ tốt', 5);
SELECT * FROM SHIPPER WHERE user_ID = 6;
-- Kết quả: diem_danh_gia cập nhật = AVG(5, 4) = 4.5

----- TEST TRIGGER TRÊN DELIVERING / FOOD / VOUCHER -----

GO
-- Đổi shipper 6 sang trạng thái ngoại tuyến
UPDATE SHIPPER
SET trang_thai = N'ngoại tuyến'
WHERE user_ID = 6;

-- Tạo đơn 301
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang)
VALUES (301, 1, 3, N'đang xử lý', N'Test đơn 301', N'Hà Nội', 70000, 10000);

-- Thử gán shipper 6 giao đơn 301 -> dự kiến lỗi do shipper không trực tuyến
INSERT INTO DELIVERING (shipper_ID, order_ID)
VALUES (6, 301);
GO

-- Kiểm tra
SELECT * FROM DELIVERING WHERE order_ID = 301;
SELECT user_ID, trang_thai FROM SHIPPER WHERE user_ID = 6;
SELECT * FROM USERS; 

-- Đảm bảo shipper 6 đang 'trực tuyến'
UPDATE SHIPPER
SET trang_thai = N'trực tuyến'
WHERE user_ID = 6;

-- Tạo đơn mới 300 cho nhà hàng 1, khách 3
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang)
VALUES (300, 1, 3, N'đang xử lý', N'Test đơn 300', N'Hà Nội', 60000, 10000);

-- Gán shipper 6 giao đơn 300 (hợp lệ)
INSERT INTO DELIVERING (shipper_ID, order_ID)
VALUES (6, 300);

-- Kiểm tra kết quả
SELECT * FROM DELIVERING;
SELECT user_ID, diem_danh_gia, trang_thai FROM SHIPPER WHERE user_ID = 6;

----------------------
-- TEST TRIGGER FOOD
----------------------
UPDATE FOOD
SET trang_thai = N'còn hàng'
WHERE food_ID = 10;

-- Thêm món 10 vào đơn 100 (hợp lệ)
INSERT INTO FOOD_ORDERED (food_ID, order_ID)
VALUES (10, 101);

-- Kiểm tra kết quả
SELECT * FROM FOOD_ORDERED WHERE order_ID = 100;

-- Đặt món 11 sang trạng thái 'hết hàng'
GO
UPDATE FOOD
SET trang_thai = N'hết hàng'
WHERE food_ID = 11;

-- Thử thêm món 11 (hết hàng) vào đơn 100 -> dự kiến lỗi
INSERT INTO FOOD_ORDERED (food_ID, order_ID)
VALUES (11, 101);

-- Kiểm tra xem có lỡ chèn vào không
SELECT * FROM FOOD_ORDERED WHERE order_ID = 100 AND food_ID = 11;
GO

---------------------------------------------------
-- TEST TRIGGER VOUCHER: KHÔNG CHO ÁP DỤNG SAU HẠN
---------------------------------------------------
GO
INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, 
                     dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
VALUES
(
    903,
    '2025-12-31',              -- hạn sử dụng
    N'TC_VOUCHER_4 - Giảm 25%',
    N'Đơn tối thiểu 200k',
    25,
    NULL,
    3
);

-- Tạo đơn với ngày tạo SAU hạn sử dụng voucher
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, 
                    gia_don_hang, phi_giao_hang, ngay_tao)
VALUES
(
    811,
    1,
    3,
    N'đang xử lý',
    N'TC_VOUCHER_4',
    N'Hà Nội',
    250000,
    20000,
    '2026-01-05'                -- > 2025-12-31
);

-- Thử gán voucher 903 cho đơn 811 (dự kiến lỗi)
UPDATE VOUCHER
SET order_ID = 811
WHERE voucher_ID = 903;

-- Kỳ vọng: trigger báo lỗi và order_ID của voucher 903 vẫn là NULL
SELECT 'VOUCHER' AS TableName, * FROM VOUCHER WHERE voucher_ID = 903;
GO

-----------------------------------------------------------
-- REGION 5: STORED PROCEDURE CRUD USERS & NGHIỆP VỤ
-----------------------------------------------------------

IF OBJECT_ID('proc_InsertUser', 'P') IS NOT NULL
    DROP PROC proc_InsertUser;
GO

CREATE PROC proc_InsertUser
    @ID             INT,
    @Ho_ten         NVARCHAR(40),
    @Email          VARCHAR(320),
    @SDT            VARCHAR(10),
    @Password       VARCHAR(100),
    @TKNH           VARCHAR(20),
    @Dia_chi        NVARCHAR(255),
    @vai_tro        VARCHAR(10),

    -- RESTAURANT
    @Thoi_gian_mo_cua   TIME(0) = NULL,
    @Thoi_gian_dong_cua TIME(0) = NULL,
    @Trang_thai_rest     NVARCHAR(14) = NULL,

    -- SHIPPER
    @bien_so_xe     VARCHAR(11) = NULL,
    @trang_thai_ship NVARCHAR(11) = NULL,

    -- ADMIN
    @quyen_han      NVARCHAR(255)=NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -------------------------------------------------------------------
        -- 1️⃣ KIỂM TRA TỒN TẠI ID / EMAIL
        -------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM USERS WHERE ID = @ID)
            THROW 50001, N'ID người dùng đã tồn tại.', 1;

        IF EXISTS (SELECT 1 FROM USERS WHERE Email = @Email)
            THROW 50002, N'Email đã tồn tại.', 1;

        -------------------------------------------------------------------
        -- 2️⃣ KIỂM TRA DỮ LIỆU CHUNG
        -------------------------------------------------------------------
        IF @Ho_ten IS NULL OR LTRIM(RTRIM(@Ho_ten)) = ''
            THROW 50003, N'Họ tên không được để trống.', 1;

        IF @Ho_ten LIKE '%[^A-Za-zÀ-ỹ ]%'
            THROW 50004, N'Họ tên chỉ được chứa chữ cái và dấu cách.', 1;

        IF @Email NOT LIKE '%_@_%._%'
            THROW 50005, N'Định dạng email không hợp lệ.', 1;

        IF LEN(@SDT) <> 10 OR @SDT NOT LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
            THROW 50006, N'Số điện thoại phải gồm đúng 10 số và bắt đầu bằng 0.', 1;

        IF LEN(@Password) < 8
            THROW 50007, N'Mật khẩu phải có ít nhất 8 ký tự.', 1;

        IF PATINDEX('%[A-Za-z]%', @Password) = 0 
            THROW 50008, N'Mật khẩu phải chứa ít nhất 1 chữ cái.', 1;

        IF PATINDEX('%[0-9]%', @Password) = 0
            THROW 50009, N'Mật khẩu phải chứa ít nhất 1 chữ số.', 1;

        IF PATINDEX('%[^A-Za-z0-9]%', @Password) = 0
            THROW 50010, N'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt.', 1;

		-- Tài khoản ngân hàng: không rỗng, chỉ chứa số, 10–16 số
		IF @TKNH IS NULL 
            THROW 50014, N'Số tài khoản ngân hàng không được để trống.', 1;

        IF @TKNH LIKE '%[^0-9]%'
            THROW 50015, N'Số tài khoản ngân hàng chỉ được chứa chữ số.', 1;

        IF LEN(@TKNH) < 10 OR LEN(@TKNH) > 16
            THROW 50016, N'Số tài khoản ngân hàng phải có từ 10 đến 16 chữ số.', 1;

		-- Địa chỉ: không rỗng
		IF @Dia_chi IS NULL OR LTRIM(RTRIM(@Dia_chi)) = ''
            THROW 50017, N'Địa chỉ không được để trống.', 1;

		-- Thêm dữ liệu sau khi kiểm tra điều kiện
		INSERT INTO USERS (ID, Ho_ten, Email, SDT, Password, TKNH, Dia_chi)
        VALUES (@ID, @Ho_ten, @Email, @SDT, @Password, @TKNH, @Dia_chi);
	END TRY
    
    -- Bắt lỗi và ném lại (THROW giữ nguyên thông tin lỗi gốc)
	BEGIN CATCH
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('proc_UpdateUser', 'P') IS NOT NULL
    DROP PROC proc_UpdateUser;
GO

CREATE PROC proc_UpdateUser
    @ID             INT,
    @Ho_ten         NVARCHAR(40),
    @Email          VARCHAR(320),
    @SDT            VARCHAR(10),
    @Password       VARCHAR(100),
    @TKNH           VARCHAR(20),
    @Dia_chi        NVARCHAR(255),

    -- Các tham số riêng (nếu user thuộc vai trò này)
    @Thoi_gian_mo_cua   TIME(0) = NULL,
    @Thoi_gian_dong_cua TIME(0) = NULL,
    @Trang_thai_rest     NVARCHAR(14) = NULL,
    @bien_so_xe          VARCHAR(11) = NULL,
    @trang_thai_ship     NVARCHAR(11) = NULL,
    @quyen_han           NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -------------------------------------------------------------------
        -- 1️⃣ KIỂM TRA TỒN TẠI USER
        -------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM USERS WHERE ID = @ID)
            THROW 50020, N'Không tìm thấy người dùng với ID cần cập nhật.', 1;

        DECLARE @vai_tro VARCHAR(10);
        SELECT @vai_tro = vai_tro FROM USERS WHERE ID = @ID;

        -------------------------------------------------------------------
        -- 2️⃣ KIỂM TRA DỮ LIỆU CHUNG
        -------------------------------------------------------------------
        IF @Ho_ten IS NULL OR LTRIM(RTRIM(@Ho_ten)) = ''
            THROW 50021, N'Họ tên không được để trống.', 1;

        IF @Ho_ten LIKE '%[^A-Za-zÀ-ỹ ]%'
            THROW 50022, N'Họ tên chỉ được chứa chữ cái và dấu cách.', 1;

        IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = ''
            THROW 50023, N'Email không được để trống.', 1;

        IF @Email NOT LIKE '%_@_%._%'
            THROW 50024, N'Định dạng email không hợp lệ.', 1;

        -- Email không được trùng với người khác
        IF EXISTS (SELECT 1 FROM USERS WHERE Email = @Email AND ID <> @ID)
            THROW 50025, N'Email đã được sử dụng bởi người dùng khác.', 1;

        IF @SDT IS NULL OR LEN(@SDT) <> 10 OR @SDT NOT LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
            THROW 50026, N'Số điện thoại phải gồm đúng 10 số và bắt đầu bằng 0.', 1;

        IF @Password IS NULL OR LEN(@Password) < 8
            THROW 50027, N'Mật khẩu phải có ít nhất 8 ký tự.', 1;

        IF PATINDEX('%[A-Za-z]%', @Password) = 0
            THROW 50028, N'Mật khẩu phải chứa ít nhất 1 chữ cái.', 1;

        IF PATINDEX('%[0-9]%', @Password) = 0
            THROW 50029, N'Mật khẩu phải chứa ít nhất 1 chữ số.', 1;

        IF PATINDEX('%[^A-Za-z0-9]%', @Password) = 0
            THROW 50030, N'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt.', 1;

		-- TKNH: không rỗng, chỉ số, 10–16
		IF @TKNH IS NULL
            THROW 50115, N'Số tài khoản ngân hàng không được để trống.', 1;

        IF @TKNH LIKE '%[^0-9]%'
            THROW 50116, N'Số tài khoản ngân hàng chỉ được chứa chữ số.', 1;

        IF LEN(@TKNH) < 10 OR LEN(@TKNH) > 16
            THROW 50117, N'Số tài khoản ngân hàng phải có từ 10 đến 16 chữ số.', 1;

		-- Địa chỉ: không rỗng
		IF @Dia_chi IS NULL OR LTRIM(RTRIM(@Dia_chi)) = ''
            THROW 50118, N'Địa chỉ không được để trống.', 1;

            UPDATE ADMIN
            SET quyen_han = @quyen_han
            WHERE user_ID = @ID;
        END

        -------------------------------------------------------------------
        -- 4️⃣ CẬP NHẬT DỮ LIỆU CHUNG TRONG USERS
        -------------------------------------------------------------------
        UPDATE USERS
        SET Ho_ten   = @Ho_ten,
            Email    = @Email,
            SDT      = @SDT,
            Password = @Password,
            TKNH     = @TKNH,
            Dia_chi  = @Dia_chi
        WHERE ID = @ID;

        PRINT N'Cập nhật người dùng thành công!';
    END TRY
    BEGIN CATCH
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- PROC proc_DeleteUser: xóa user nếu không dính khách/nhà hàng/shipper đã có dữ liệu phát sinh
IF OBJECT_ID('proc_DeleteUser', 'P') IS NOT NULL
    DROP PROC proc_DeleteUser;
GO

CREATE PROC proc_DeleteUser
    @UserID        INT
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY
		-- Kiểm tra tồn tại user
		IF NOT EXISTS (SELECT 1 FROM USERS WHERE ID = @UserID)
            THROW 50039, N'Không tìm thấy người dùng với ID cần xóa', 1;

		-- Nếu là CUSTOMER có đơn hàng
		IF EXISTS (
            SELECT 1
            FROM CUSTOMER c
            JOIN ORDERS o ON o.customer_ID = c.user_ID
            WHERE c.user_ID = @UserID
        )
            THROW 50040, N'Không thể xóa người dùng vì là khách hàng đã có đơn hàng', 1;

		-- Nếu là RESTAURANT có đơn hàng
		IF EXISTS (
            SELECT 1
            FROM RESTAURANT r
            JOIN ORDERS o ON o.restaurant_ID = r.user_ID
            WHERE r.user_ID = @UserID
        )
			THROW 50041,  N'Không thể xóa người dùng vì là nhà hàng đã có đơn hàng', 1;

		-- Nếu là SHIPPER đã/đang giao đơn
		IF EXISTS (
            SELECT 1
            FROM SHIPPER s
            JOIN DELIVERING d ON d.shipper_ID = s.user_ID
            WHERE s.user_ID = @UserID
        )
			THROW 50042, N'Không thể xóa người dùng vì là shipper đã/đang giao đơn', 1;

		-- Xóa dữ liệu sau khi kiểm tra điều kiện
		DELETE FROM USERS
		WHERE ID = @UserID;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT;
        SELECT	@ErrMsg = ERROR_MESSAGE(),
				@ErrSeverity = ERROR_SEVERITY();

        RAISERROR (@ErrMsg, @ErrSeverity, 1);
    END CATCH
END;
GO
SELECT * FROM USERS;
SELECT * FROM RESTAURANT;

-- TEST CRUD USERS

EXEC proc_InsertUser
    @ID = 1001,
    @Ho_ten = N'Nhà Hàng Gió Biển',
    @Email = 'gionbien@res.com',
    @SDT = '0901234567',
    @Password = 'Abc@1234',
    @TKNH = '123456789012',
    @Dia_chi = N'Hà Nội',
    @vai_tro = 'RESTAURANT',
    @Thoi_gian_mo_cua = '08:00',
    @Thoi_gian_dong_cua = '22:00',
    @Trang_thai_rest = N'đang hoạt động';

EXEC UpdateUser
    @ID        = 7,
    @Ho_ten    = N'Phạm Nhân',
    @Email     = 'nhan.phamhong.updated@hcmut.edu.vn',
    @SDT       = '0911223344',
    @Password  = 'NewPass@123',
    @TKNH      = '999888777666',
    @Dia_chi   = N'Thủ Đức, TP.HCM';

EXEC DeleteUser
    @UserID = 7;

GO

-----------------------------------------------------------
-- REGION 6: PROC TRUY VẤN THỐNG KÊ ĐƠN HÀNG
-----------------------------------------------------------

-- proc_GetOrderByCustomerAndStatus: lấy danh sách đơn của 1 khách theo trạng thái
IF OBJECT_ID('proc_GetOrderByCustomerAndStatus', 'P') IS NOT NULL
	DROP PROC proc_GetOrderByCustomerAndStatus;
GO

CREATE PROC proc_GetOrderByCustomerAndStatus
	@CustomerID		INT,
	@TrangThai		NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		o.order_ID,
		o.ngay_tao,
		o.trang_thai,
		o.gia_don_hang,
		o.phi_giao_hang,
		r.user_ID			AS restaurant_ID,
		u.Ho_ten			AS restaurant_name,
		o.dia_chi
	FROM ORDERS o
	JOIN RESTAURANT r
		ON o.restaurant_ID = r.user_ID
	JOIN USERS u
		ON r.user_ID = u.ID
	WHERE
		o.customer_ID = @CustomerID
		AND o.trang_thai = @TrangThai
	ORDER BY
		o.ngay_tao DESC;
END;
GO

-- proc_GetRestaurantSalesStats: thống kê doanh thu nhà hàng trong khoảng thời gian
IF OBJECT_ID('proc_GetRestaurantSalesStats', 'P') IS NOT NULL
	DROP PROC proc_GetRestaurantSalesStats;
GO

CREATE PROC proc_GetRestaurantSalesStats
	@FromDate		DATETIME,
	@ToDate			DATETIME,
	@MinTotal		DECIMAL(10,2)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
        r.user_ID                   AS restaurant_ID,
        u.Ho_ten                    AS restaurant_name,
        COUNT(o.order_ID)           AS so_don_hang,
        SUM(o.gia_don_hang)         AS tong_doanh_thu,
        AVG(o.gia_don_hang)         AS gia_tri_trung_binh
    FROM ORDERS o
    JOIN RESTAURANT r
        ON o.restaurant_ID = r.user_ID
    JOIN USERS u
        ON r.user_ID = u.ID
    WHERE 
        o.ngay_tao >= @FromDate
        AND o.ngay_tao <  @ToDate
    GROUP BY 
        r.user_ID,
        u.Ho_ten
    HAVING 
        SUM(o.gia_don_hang) >= @MinTotal
    ORDER BY 
        tong_doanh_thu DESC;
END;
GO

-- TEST PROC THỐNG KÊ
EXEC proc_GetOrderByCustomerAndStatus
	@CustomerID = 3,
	@TrangThai = N'đang xử lý';
GO

EXEC proc_GetRestaurantSalesStats
	@FromDate = '2024-01-01',
	@ToDate = '2026-01-01',
	@MinTotal = 50000;

-----------------------------------------------------------
-- REGION 7: FUNCTION TÍNH TOÁN / PHÂN HẠNG
-----------------------------------------------------------

-- sửa lại thêm phân loại để tăng để phức tạp của hàm
-- fn_TongChiTieuKhachHang: tính tổng chi tiêu (giá đơn + phí giao) của 1 khách trong khoảng thời gian và phân loại <0;<100;<200 và >200
IF OBJECT_ID('fn_TongChiTieuKhachHang', 'FN') IS NOT NULL   
    DROP FUNCTION fn_TongChiTieuKhachHang;
GO

CREATE FUNCTION fn_TongChiTieuKhachHang
(
    @CustomerID INT,
    @FromDate   DATETIME,
    @ToDate     DATETIME
)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE 
        @TongChi   DECIMAL(18,2) = 0,
        @GiaDon    DECIMAL(18,2),
        @SoDon     INT = 0,
        @TrungBinh DECIMAL(18,2),
        @DanhGia   NVARCHAR(50),
        @KetQua    NVARCHAR(200);

    -- Kiểm tra tham số đầu vào
    IF @CustomerID IS NULL OR @FromDate IS NULL OR @ToDate IS NULL
        RETURN NULL;

    IF @FromDate > @ToDate
        RETURN NULL;

    -- Kiểm tra khách hàng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM CUSTOMER WHERE user_ID = @CustomerID)
        RETURN NULL;

    -- CURSOR duyệt qua từng đơn hàng của khách (đã hoàn tất) trong khoảng thời gian
    DECLARE cur_Order CURSOR LOCAL FOR
        SELECT (gia_don_hang + phi_giao_hang)
        FROM ORDERS
        WHERE customer_ID = @CustomerID
          AND ngay_tao >= @FromDate
          AND ngay_tao <  @ToDate
          AND trang_thai = N'hoàn tất'; 

    OPEN cur_Order;

    FETCH NEXT FROM cur_Order INTO @GiaDon;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TongChi = @TongChi + @GiaDon;
        SET @SoDon   = @SoDon + 1;
        FETCH NEXT FROM cur_Order INTO @GiaDon;
    END

    CLOSE cur_Order;
    DEALLOCATE cur_Order; 

    IF @SoDon > 0
        SET @TrungBinh = @TongChi / @SoDon;
    ELSE
        SET @TrungBinh = 0;

    IF @TongChi = 0
        SET @DanhGia = N'SẮT';
    ELSE IF @TongChi < 100000
        SET @DanhGia = N'ĐỒNG';
    ELSE IF @TongChi < 200000
        SET @DanhGia = N'BẠC';
    ELSE
        SET @DanhGia = N'VÀNG VIP PRO';

    SET @KetQua = N'Khách hàng ID ' + CAST(@CustomerID AS NVARCHAR) 
                + N': Tổng chi tiêu = ' + CAST(@TongChi AS NVARCHAR)
                + N' (Số đơn = ' + CAST(@SoDon AS NVARCHAR)
                + N', Trung bình = ' + CAST(@TrungBinh AS NVARCHAR)
                + N') : ' + @DanhGia;

    RETURN @KetQua;
END;
GO

SELECT dbo.fn_TongChiTieuKhachHang(102, '2025-01-01', '2025-12-31') AS KetQua;

-- TEST FUNCTION TỔNG CHI TIÊU
SELECT * FROM CUSTOMER;
SELECT * FROM ORDERS;
SELECT dbo.fn_TongChiTieuKhachHang(3, '2024-01-01', '2026-01-01') AS TongChiTieu_KH3;
SELECT dbo.fn_TongChiTieuKhachHang(4, '2024-01-01', '2026-01-01') AS TongChiTieu_KH3;

SELECT dbo.fn_TongChiTieuKhachHang(999, '2024-01-01', '2026-01-01') AS TongChi_KH_KhongTonTai; -- khách không tồn tại -> NULL

--fn_TongTienTietKiemTuVoucher: tính số tiền tiết kiệm từ voucher
IF OBJECT_ID('fn_TongTienTietKiemTuVoucher', 'FN') IS NOT NULL
    DROP FUNCTION fn_TongTienTietKiemTuVoucher;
GO

CREATE FUNCTION fn_TongTienTietKiemTuVoucher
(
    @CustomerID INT,
    @FromDate   DATETIME,
    @ToDate     DATETIME
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongTietKiem   DECIMAL(18,2) = 0;
    DECLARE @GiaDonHang     DECIMAL(18,2);
    DECLARE @PhiGiaoHang    DECIMAL(18,2);
    DECLARE @PhanTramGiam   INT;
    DECLARE @DieuKienSuDung NVARCHAR(255);
    DECLARE @MoTa           NVARCHAR(255);
    DECLARE @MinOrderValue  DECIMAL(18,2) = 0; 
    DECLARE @TempString     NVARCHAR(255);
    DECLARE @StartPos       INT;

    -- 1. Kiểm tra tham số đầu vào
    IF @CustomerID IS NULL OR @FromDate IS NULL OR @ToDate IS NULL
        RETURN -1.0;

    IF @FromDate > @ToDate
        RETURN -2.0;

    -- 2. Kiểm tra khách hàng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM CUSTOMER WHERE user_ID = @CustomerID)
        RETURN -3.0;

    /* 3. CURSOR duyệt từng đơn hàng có áp dụng voucher 
          của khách hàng trong khoảng thời gian [FromDate, ToDate) */
    DECLARE cur_Voucher CURSOR LOCAL FAST_FORWARD FOR
        SELECT 
            o.gia_don_hang,
            o.phi_giao_hang,
            v.gia_tri_su_dung,
            v.dieu_kien_su_dung,
            v.mo_ta
        FROM VOUCHER v
        JOIN ORDERS o ON v.order_ID = o.order_ID
        WHERE 
            v.customer_ID = @CustomerID
            AND v.order_ID IS NOT NULL
            AND o.ngay_tao >= @FromDate
            AND o.ngay_tao <  @ToDate;

    OPEN cur_Voucher;

    FETCH NEXT FROM cur_Voucher 
        INTO @GiaDonHang, @PhiGiaoHang, @PhanTramGiam, @DieuKienSuDung, @MoTa;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Tính số tiền giảm cho đơn này
        SET @TienGiam = (@GiaDon * @PhanTramGiam) / 100.0;

        -- (Option) Bảo vệ: không giảm quá số tiền đơn
        IF @TienGiam > @GiaDon
            SET @TienGiam = @GiaDon;

        -- Cộng dồn
        SET @TongTietKiem = @TongTietKiem + ISNULL(@TienGiam, 0);

        FETCH NEXT FROM cur_Voucher 
            INTO @GiaDonHang, @PhiGiaoHang, @PhanTramGiam, @DieuKienSuDung, @MoTa;
    END

    CLOSE cur_Voucher;
    DEALLOCATE cur_Voucher;

    RETURN @TongTietKiem;
END;
GO

GO
-- TEST FUNCTION TIẾT KIỆM 
-- Tổng tiền khách 4 đã tiết kiệm nhờ voucher từ 2024 đến 2026
SELECT dbo.fn_TongTienTietKiemTuVoucher(4, '2024-01-01', '2026-01-01') AS TongTienTietKiem_KH4;

-- Customer không tồn tại
SELECT dbo.fn_TongTienTietKiemTuVoucher(999, '2024-01-01', '2026-01-01') AS TongTienTietKiem_KH999;

    -----------------------------------------------------------
    -- REGION 7.5: STORED PROCEDURES CHO QUẢN LÝ ORDERS (CHO PHẦN 3.2)
    -----------------------------------------------------------

    -- UpdateOrderStatus: Cập nhật trạng thái đơn hàng với kiểm tra logic
    IF OBJECT_ID('UpdateOrderStatus', 'P') IS NOT NULL
        DROP PROC UpdateOrderStatus;
    GO

    CREATE PROC UpdateOrderStatus
        @OrderID       INT,
        @TrangThai     NVARCHAR(50)
    AS
    BEGIN
        SET NOCOUNT ON;
        
        BEGIN TRY
            -- Kiểm tra đơn hàng tồn tại
            IF NOT EXISTS (SELECT 1 FROM ORDERS WHERE order_ID = @OrderID)
                THROW 50300, N'Không tìm thấy đơn hàng với ID cần cập nhật.', 1;
            
            -- Kiểm tra trạng thái hợp lệ
            IF @TrangThai NOT IN (N'đang xử lý', N'đang giao', N'hoàn tất', N'hủy')
                THROW 50301, N'Trạng thái không hợp lệ. Các trạng thái hợp lệ: đang xử lý, đang giao, hoàn tất, hủy', 1;
            
            -- Lấy trạng thái hiện tại
            DECLARE @CurrentStatus NVARCHAR(50);
            SELECT @CurrentStatus = trang_thai FROM ORDERS WHERE order_ID = @OrderID;
            
            -- Kiểm tra logic chuyển trạng thái
            IF @CurrentStatus IN (N'hoàn tất', N'hủy')
                THROW 50302, N'Không thể thay đổi trạng thái đơn hàng đã hoàn tất hoặc đã hủy', 1;
            
            IF @CurrentStatus = N'đang xử lý' AND @TrangThai NOT IN (N'đang giao', N'hủy')
                THROW 50303, N'Đơn hàng đang xử lý chỉ có thể chuyển sang "đang giao" hoặc "hủy"', 1;
            
            IF @CurrentStatus = N'đang giao' AND @TrangThai <> N'hoàn tất'
                THROW 50304, N'Đơn hàng đang giao chỉ có thể chuyển sang "hoàn tất"', 1;
            
            -- Cập nhật trạng thái (trigger sẽ kiểm tra logic)
            UPDATE ORDERS
            SET trang_thai = @TrangThai
            WHERE order_ID = @OrderID;
            
        END TRY
        BEGIN CATCH
            THROW;
        END CATCH
    END;
    GO

    -- DeleteOrder: Xóa đơn hàng (chỉ cho phép xóa đơn đã hủy)
    IF OBJECT_ID('DeleteOrder', 'P') IS NOT NULL
        DROP PROC DeleteOrder;
    GO

    CREATE PROC DeleteOrder
        @OrderID       INT
    AS
    BEGIN
        SET NOCOUNT ON;
        
        BEGIN TRY
            -- Kiểm tra đơn hàng tồn tại
            IF NOT EXISTS (SELECT 1 FROM ORDERS WHERE order_ID = @OrderID)
                THROW 50400, N'Không tìm thấy đơn hàng với ID cần xóa.', 1;
            
            -- Chỉ cho phép xóa đơn đã hủy
            IF NOT EXISTS (SELECT 1 FROM ORDERS WHERE order_ID = @OrderID AND trang_thai = N'hủy')
                THROW 50401, N'Chỉ có thể xóa đơn hàng đã ở trạng thái "hủy"', 1;
            
            -- Xóa đơn hàng (CASCADE sẽ xóa các bản ghi liên quan)
            DELETE FROM ORDERS
            WHERE order_ID = @OrderID;
            
        END TRY
        BEGIN CATCH
            THROW;
        END CATCH
    END;
    GO

-----------------------------------------------------------
-- REGION 8: XEM LẠI TOÀN BỘ DỮ LIỆU
-----------------------------------------------------------

SELECT 'USERS' AS Ten_bang, * FROM USERS;
SELECT 'RESTAURANT' AS Ten_bang, * FROM RESTAURANT;
SELECT 'CUSTOMER' AS Ten_bang, * FROM CUSTOMER;
SELECT 'SHIPPER' AS Ten_bang, * FROM SHIPPER;
SELECT 'ADMIN' AS Ten_bang, * FROM ADMIN;
SELECT 'FOOD' AS Ten_bang, * FROM FOOD;
SELECT 'ORDERS' AS Ten_bang, * FROM ORDERS;
SELECT 'RATING' AS Ten_bang, * FROM RATING;
SELECT 'DELIVERING' AS Ten_bang, * FROM DELIVERING;
SELECT 'PARENT RESTAURANT' AS Ten_bang, * FROM PARENT_RESTAURANT;
SELECT 'VOUCHER' AS Ten_bang, * FROM VOUCHER;
SELECT 'FOOD_BELONG' AS Ten_bang, * FROM FOOD_BELONG;
SELECT 'FOOD_ORDERED' AS Ten_bang, * FROM FOOD_ORDERED;
