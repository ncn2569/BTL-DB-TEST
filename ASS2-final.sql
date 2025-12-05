    -----------------------------------------------------------
-- REGION 1: TẠO BẢNG & INSERT DỮ LIỆU MẪU
-----------------------------------------------------------

-- Xóa các bảng con trước, bảng cha sau để tránh lỗi khóa ngoại
IF OBJECT_ID('DELIVERING', 'U') IS NOT NULL DROP TABLE DELIVERING;
--IF OBJECT_ID('RATING_FOOD', 'U') IS NOT NULL DROP TABLE RATING_FOOD;--để đây để nếu ai còn bảng rating food thì bỏ
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
-- TIME(0) = HH:MM:SS, không phần thập phân giây
    Thoi_gian_mo_cua   TIME(0) NOT NULL,  
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
    -- đổi từ cascade thành no action không thể xóa nhà hàng khi đang có đơn hàng ứng với nhà hàng đó
    FOREIGN KEY (restaurant_ID) REFERENCES RESTAURANT(user_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
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
GO

-- RATING: ngày đánh giá phải > ngày tạo đơn
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
END;
GO


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
(101), (102), (103), (104), (105);
INSERT INTO SHIPPER (user_ID, bien_so_xe, trang_thai) VALUES
(301, '30-A1-12345', N'trực tuyến'),
(302, '30-A2-67890', N'trực tuyến'),
(303, '30-B1-11111', N'trực tuyến'),
(304, '30-B2-22222', N'trực tuyến'),
(305, '30-B3-33333', N'đang bận');
INSERT INTO ADMIN (user_ID, quyen_han) VALUES
(1, N'Quản trị hệ thống'),
(2, N'Quản lý người dùng'),
(3, N'Quản lý nhà hàng'),
(4, N'Quản lý khuyến mãi'),
(5, N'Hỗ trợ khách hàng');
INSERT INTO FOOD (food_ID, gia, ten, mo_ta, trang_thai, anh, diem_danh_gia) VALUES
(1000, 30000, N'Bánh mì thịt', N'Bánh mì Việt Nam', N'còn hàng', 'banhmi.jpg', 4.8),
(1001, 45000, N'Phở bò', N'Phở truyền thống', N'còn hàng', 'pho.jpg', 4.9),
(1002, 25000, N'Trà đá', N'Nước giải khát', N'còn hàng', 'trada.jpg', 4.0),
(1003, 50000, N'Cơm gà xối mỡ', N'Cơm nóng, gà giòn', N'còn hàng', 'comga.jpg', 4.4),
(1004, 20000, N'Nước cam', N'Cam tươi nguyên chất', N'hết hàng', 'nuoccam.jpg', 4.2),
(1005, 35000, N'Bún chả', N'Bún chả Hà Nội', N'còn hàng', 'buncha.jpg', 4.5),
(1006, 60000, N'Pizza hải sản', N'Pizza cỡ nhỏ', N'còn hàng', 'pizza.jpg', 3.9),
(1007, 15000, N'Trà sữa trân châu', N'Trà sữa truyền thống', N'còn hàng', 'trasua.jpg', 4.1),
(1008, 40000, N'Gà rán', N'Gà giòn cay', N'còn hàng', 'garan.jpg', 4.6),
(1009, 25000, N'Bánh flan', N'Món tráng miệng', N'còn hàng', 'flan.jpg', 4.7);
INSERT INTO FOOD_BELONG VALUES
(1000, 201), (1001, 201), (1002, 201),
(1003, 202), (1004, 202),
(1005, 203),
(1006, 204), (1007, 204),
(1008, 205), (1009, 205);
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang)
VALUES
(500, 201, 101, N'đang xử lý', N'Không cay', N'Hà Nội', 75000, 15000),
(501, 201, 102, N'hoàn tất', N'Ít nước', N'TP.HCM', 60000, 10000),
(502, 203, 103, N'hoàn tất', N'Thêm hành', N'Đà Nẵng', 80000, 12000),
(503, 203, 104, N'đang giao', N'Giao nhanh', N'Cần Thơ', 90000, 15000),
(504, 204, 105, N'đang xử lý', NULL, N'Huế', 70000, 10000);
INSERT INTO FOOD_ORDERED VALUES
(1000, 500),
(1001, 501),
(1003, 502),
(1005, 503),
(1006, 504);
INSERT INTO DELIVERING (shipper_ID, order_ID) VALUES
(301, 500),
(302, 503),
(303, 504);
INSERT INTO RATING (order_ID, rating_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES
(501, 1, 1001, N'Phở ngon, ship nhanh.', 5),
(502, 1, 1003, N'Cơm gà ngon, gói kỹ.', 4);
INSERT INTO PARENT_RESTAURANT (parent_id, child_id) VALUES
(201, 202),
(201, 203),
(204, 205);
INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
VALUES
(900, '2026-01-01', N'Giảm 30%', N'Đơn tối thiểu 50k', 30, 501, 102),
(901, '2026-06-01', N'Giảm 20%', N'Đơn tối thiểu 80k', 20, 502, 103),
(902, '2026-12-31', N'Freeship 100%', N'Đơn tối thiểu 0k', 100, NULL, 104),
(903, '2026-03-15', N'Giảm 10%', N'Đơn tối thiểu 100k', 10, NULL, 105);


GO

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

    UPDATE f
    SET f.Diem_danh_gia =
        ISNULL(
            (
                SELECT AVG(CAST(r.Diem_danh_gia AS DECIMAL(3,2)))
                FROM RATING r
                WHERE r.food_ID = f.food_ID
            ),
            3   -- điểm mặc định nếu không còn rating
        )
    FROM FOOD f
    WHERE f.food_ID IN (
        SELECT food_ID FROM inserted
        UNION
        SELECT food_ID FROM deleted
    );
END;
GO
-----------------------------------
---- TEST MỘT SỐ TRIGGER NGHIỆP VỤ
-----------------------------------
-- 
INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
VALUES
(904, '2025-12-10', N'Giảm 30%',N'Đơn tối thiểu 50k',  30, 504, 101);

SELECT * FROM VOUCHER;
SELECT * FROM ORDERS;
SELECT * FROM CUSTOMER;
SELECT * FROM RATING;
SELECT * FROM FOOD;

-- set trạng thái hủy
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 504;
-- Kiểm tra Voucher sau khi hủy đơn
SELECT * FROM VOUCHER WHERE voucher_ID = 904;

-- thêm đơn vào rating
INSERT INTO RATING (order_ID, rating_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES
(501, 3, 1001, N'Ngon và nhanh.',2);
-- Xóa rating
DELETE RATING WHERE rating_ID= 2;
-- Cập nhật rating
UPDATE RATING 
SET Diem_danh_gia = 1
WHERE rating_ID = 3;

GO
-- 
SELECT * FROM FOOD; 
SELECT * FROM ORDERS;

INSERT INTO RATING (order_ID, rating_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES
(502, 2, 1000, N'Ngon và nhanh.',                      4);
INSERT INTO RATING (order_ID, rating_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES
(502, 3, 1000, N'Ngon và nhanh.',                      3);
----------------------------------------------------------
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

        IF @TKNH LIKE '%[^0-9]%' OR LEN(@TKNH) < 10 OR LEN(@TKNH) > 16
            THROW 50011, N'Số tài khoản ngân hàng không hợp lệ.', 1;

        IF LTRIM(RTRIM(@Dia_chi)) = ''
            THROW 50012, N'Địa chỉ không được để trống.', 1;

        IF @vai_tro NOT IN ('RESTAURANT','SHIPPER','CUSTOMER','ADMIN')
            THROW 50013, N'Vai trò không hợp lệ.', 1;

        -------------------------------------------------------------------
        -- 3️⃣ KIỂM TRA TRƯỚC DỮ LIỆU THEO VAI TRÒ
        -------------------------------------------------------------------
        IF @vai_tro = 'RESTAURANT'
        BEGIN
            IF @Thoi_gian_mo_cua IS NULL OR @Thoi_gian_dong_cua IS NULL OR @Trang_thai_rest IS NULL
                THROW 50014, N'Nhà hàng cần nhập giờ mở cửa, đóng cửa và trạng thái.', 1;

            IF @Thoi_gian_mo_cua >= @Thoi_gian_dong_cua
                THROW 50015, N'Giờ mở cửa phải nhỏ hơn giờ đóng cửa.', 1;

            IF @Trang_thai_rest NOT IN (N'đang hoạt động', N'tạm nghỉ', N'đóng cửa')
                THROW 50016, N'Trạng thái nhà hàng không hợp lệ.', 1;
        END
        ELSE IF @vai_tro = 'SHIPPER'
        BEGIN
            IF @bien_so_xe IS NULL OR @trang_thai_ship IS NULL
                THROW 50017, N'Shipper cần nhập biển số xe và trạng thái.', 1;

            IF @trang_thai_ship NOT IN (N'trực tuyến', N'ngoại tuyến', N'đang bận')
                THROW 50018, N'Trạng thái shipper không hợp lệ.', 1;
            IF @bien_so_xe NOT LIKE '[0-9][0-9]-[A-Z][0-9]-[0-9][0-9][0-9][0-9][0-9]%'
               AND @bien_so_xe NOT LIKE '[0-9][0-9]-[A-Z][A-Z]-[0-9][0-9][0-9][0-9][0-9]%'
               THROW 50180, N'Biển số xe không hợp lệ.', 1;
        END
        ELSE IF @vai_tro = 'ADMIN'
        BEGIN
            IF @quyen_han IS NULL OR LTRIM(RTRIM(@quyen_han)) = ''
                THROW 50019, N'Quyền hạn ADMIN không được để trống.', 1;
        END

        -------------------------------------------------------------------
        -- 4️⃣ CHỈ KHI TẤT CẢ HỢP LỆ → MỚI THÊM DỮ LIỆU
        -------------------------------------------------------------------
        INSERT INTO USERS (ID, Ho_ten, Email, SDT, Password, TKNH, Dia_chi, vai_tro)
        VALUES (@ID, @Ho_ten, @Email, @SDT, @Password, @TKNH, @Dia_chi, @vai_tro);

        IF @vai_tro = 'RESTAURANT'
            INSERT INTO RESTAURANT VALUES(@ID, @Thoi_gian_mo_cua, @Thoi_gian_dong_cua, @Trang_thai_rest);
        ELSE IF @vai_tro = 'CUSTOMER'
            INSERT INTO CUSTOMER VALUES(@ID);
        ELSE IF @vai_tro = 'SHIPPER'
            INSERT INTO SHIPPER VALUES(@ID, @bien_so_xe, @trang_thai_ship);
        ELSE IF @vai_tro = 'ADMIN'
            INSERT INTO ADMIN VALUES(@ID, @quyen_han);

        PRINT N'Thêm người dùng mới thành công!';
    END TRY
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

        IF @TKNH IS NULL OR @TKNH LIKE '%[^0-9]%' OR LEN(@TKNH) < 10 OR LEN(@TKNH) > 16
            THROW 50031, N'Số tài khoản ngân hàng không hợp lệ.', 1;

        IF @Dia_chi IS NULL OR LTRIM(RTRIM(@Dia_chi)) = ''
            THROW 50032, N'Địa chỉ không được để trống.', 1;

        -------------------------------------------------------------------
        -- 3️⃣ KIỂM TRA RIÊNG CHO TỪNG VAI TRÒ
        -------------------------------------------------------------------
        IF @vai_tro = 'RESTAURANT'
        BEGIN
            IF @Thoi_gian_mo_cua IS NULL OR @Thoi_gian_dong_cua IS NULL OR @Trang_thai_rest IS NULL
                THROW 50033, N'Nhà hàng cần nhập giờ mở cửa, đóng cửa và trạng thái.', 1;

            IF @Thoi_gian_mo_cua >= @Thoi_gian_dong_cua
                THROW 50034, N'Giờ mở cửa phải nhỏ hơn giờ đóng cửa.', 1;

            IF @Trang_thai_rest NOT IN (N'đang hoạt động', N'tạm nghỉ', N'đóng cửa')
                THROW 50035, N'Trạng thái nhà hàng không hợp lệ.', 1;

            UPDATE RESTAURANT
            SET Thoi_gian_mo_cua = @Thoi_gian_mo_cua,
                Thoi_gian_dong_cua = @Thoi_gian_dong_cua,
                Trang_thai = @Trang_thai_rest
            WHERE user_ID = @ID;
        END
        ELSE IF @vai_tro = 'SHIPPER'
        BEGIN
            IF @bien_so_xe IS NULL OR @trang_thai_ship IS NULL
                THROW 50036, N'Shipper cần nhập biển số xe và trạng thái.', 1;

            IF @trang_thai_ship NOT IN (N'trực tuyến', N'ngoại tuyến', N'đang bận')
                THROW 50037, N'Trạng thái shipper không hợp lệ.', 1;
            IF @bien_so_xe NOT LIKE '[0-9][0-9]-[A-Z][0-9]-[0-9][0-9][0-9][0-9][0-9]%'
               AND @bien_so_xe NOT LIKE '[0-9][0-9]-[A-Z][A-Z]-[0-9][0-9][0-9][0-9][0-9]%'
               THROW 50370, N'Biển số xe không hợp lệ.', 1;
            UPDATE SHIPPER
            SET bien_so_xe = @bien_so_xe,
                trang_thai = @trang_thai_ship
            WHERE user_ID = @ID;
        END
        ELSE IF @vai_tro = 'ADMIN'
        BEGIN
            IF @quyen_han IS NULL OR LTRIM(RTRIM(@quyen_han)) = ''
                THROW 50038, N'Quyền hạn ADMIN không được để trống.', 1;

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
        THROW
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

EXEC proc_UpdateUser
    @ID = 1001,
    @Ho_ten = N'Nhà Hàng Gió Biển Mới',
    @Email = 'gionbien_new@res.com',
    @SDT = '0909999999',
    @Password = 'New@1234',
    @TKNH = '123123123123',
    @Dia_chi = N'Ba Đình, Hà Nội',
    @Thoi_gian_mo_cua = '07:30',
    @Thoi_gian_dong_cua = '21:30',
    @Trang_thai_rest = N'tạm nghỉ';

EXEC proc_DeleteUser
    @UserID = 1001;

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
        RETURN N'THAM SỐ KHÔNG NULL'; 

    IF @FromDate > @ToDate
        RETURN N'KHOẢNG THỜI GIAN KHÔNG HỢP LỆ';

    -- Kiểm tra khách hàng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM CUSTOMER WHERE user_ID = @CustomerID)
        RETURN N'KHÁCH HÀNG KHÔNG TỒN TẠI'; 

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

-- Case 1: CustomerID = NULL
SELECT dbo.fn_TongChiTieuKhachHang(NULL, '2025-01-01', '2025-12-31') AS KQ;
-- Mong đợi: THAM SỐ KHÔNG NULL

-- Case 2: Ngày bắt đầu sau ngày kết thúc
SELECT dbo.fn_TongChiTieuKhachHang(101, '2025-12-31', '2025-01-01') AS KQ;
-- Mong đợi: KHOẢNG THỜI GIAN KHÔNG HỢP LỆ

-- Case 3: CustomerID = 999 (không có trong bảng)
SELECT dbo.fn_TongChiTieuKhachHang(999, '2025-01-01', '2025-12-31') AS KQ;
-- Mong đợi: KHÁCH HÀNG KHÔNG TỒN TẠI

-- Case 4: Customer chưa có đơn "hoàn tất"
-- place holder cho chưa có đơn hoàn tất (SELECT dbo.fn_TongChiTieuKhachHang(105, '2025-01-01', '2025-12-31') AS KQ;)
-- Mong đợi: Khách hàng ID 105: Tổng chi tiêu = 0.00 (Số đơn = 0, Trung bình = 0.00) : SẮT (vì chưa có đơn hoàn tất)

-- Case 5: Khoảng ngày không chứa đơn nào
-- place holder cho chưa có đơn (SELECT dbo.fn_TongChiTieuKhachHang(101, '2026-01-01', '2026-12-31') AS KQ;)
-- Mong đợi: Khách hàng ID 101: Tổng chi tiêu = 0.00 (Số đơn = 0, Trung bình = 0.00) : SẮT (vì không có đơn hoàn tất trong khoảng)

-- chỉnh lại theo data chính thức lần sau
-- Case 6: Customer có đơn hoàn tất 
SELECT dbo.fn_TongChiTieuKhachHang(102, '2025-01-01', '2025-12-31') AS KQ;
-- Mong đợi: Khách hàng ID 102: Tổng chi tiêu = 70000.00 (Số đơn = 1, Trung bình = 70000.00) : ĐỒNG

---- Tạo thêm đơn hoàn tất cho cùng khách (place holder)
--INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang, ngay_tao)
--VALUES (602, 201, 102, N'hoàn tất', N'Thêm test', N'TP.HCM', 90000, 10000, '2025-04-01');

---- Case 7: Tính tổng nhiều đơn place holder chờ data chính thức
--SELECT dbo.fn_TongChiTieuKhachHang(102, '2025-01-01', '2025-12-31') AS KQ;
-- Mong đợi: Khách hàng ID 102: Tổng chi tiêu = 170000.00 (Số đơn = 2, Trung bình = 85000.00) : BẠC



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

    -- 3. CURSOR duyệt từng đơn hàng có áp dụng voucher
    DECLARE cur_Voucher CURSOR LOCAL FAST_FORWARD FOR -- fast forward (tối ưu cho việc chỉ đọc và duyệt tiến)
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
        SET @MinOrderValue = 0;

        -- Parse "Đơn tối thiểu 50k" -> 50000
        IF @DieuKienSuDung LIKE N'Đơn tối thiểu %k'
        BEGIN
            SET @StartPos = PATINDEX('%[0-9]%', @DieuKienSuDung); -- vị trí bắt đầu số tiền
            IF @StartPos > 0
            BEGIN
                --temp string = cat chuoi len dksd - len startpos - len('k') + 1  
                SET @TempString = SUBSTRING(@DieuKienSuDung, 
                                            @StartPos, 
                                            LEN(@DieuKienSuDung) - @StartPos );
                                
                IF ISNUMERIC(@TempString) = 1
                    SET @MinOrderValue = CAST(@TempString AS DECIMAL(18,2)) * 1000;
            END
        END

        -- Nếu đơn >= điều kiện tối thiểu mới tính tiền giảm
        IF @GiaDonHang >= @MinOrderValue
        BEGIN
            -- Nếu là freeship -> giảm theo phí giao hàng
            IF @MoTa LIKE N'Freeship%'
                SET @TongTietKiem = @TongTietKiem + (@PhiGiaoHang * @PhanTramGiam / 100.0);
            ELSE
                SET @TongTietKiem = @TongTietKiem + (@GiaDonHang * @PhanTramGiam / 100.0);
        END

        FETCH NEXT FROM cur_Voucher 
            INTO @GiaDonHang, @PhiGiaoHang, @PhanTramGiam, @DieuKienSuDung, @MoTa;
    END

    CLOSE cur_Voucher;
    DEALLOCATE cur_Voucher;

    RETURN @TongTietKiem;
END;
GO

--case 1
SELECT dbo.fn_TongTienTietKiemTuVoucher(NULL, '2025-01-01', '2025-12-31') AS KQ;
-- Mong đợi: -1 (tham số NULL)

-- case 2
SELECT dbo.fn_TongTienTietKiemTuVoucher(101, '2025-12-31', '2025-01-01') AS KQ;
-- Mong đợi: -2 (ngày bắt đầu sau ngày kết thúc)

-- case 3
SELECT dbo.fn_TongTienTietKiemTuVoucher(999, '2025-01-01', '2025-12-31') AS KQ;
-- Mong đợi: -3 (không có khách hàng)

-- case 4
SELECT dbo.fn_TongTienTietKiemTuVoucher(105, '2025-01-01', '2025-12-31') AS KQ;
-- 👉 Mong đợi: 0.00 (không có đơn áp dụng voucher)

--case 5
SELECT * FROM VOUCHER WHERE customer_ID = 102;
SELECT dbo.fn_TongTienTietKiemTuVoucher(102, '2025-01-01', '2025-12-31') AS KQ;
-- Tính: (gia_don_hang * 30%) = 60000 * 0.3 = 18000
-- Mong đợi: 18000.00

-- case 6: không đạt đơn tối thiểu.
--INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
--VALUES (910, '2026-01-01', N'Giảm 20%', N'Đơn tối thiểu 200k', 20, 501, 102);
SELECT dbo.fn_TongTienTietKiemTuVoucher(102, '2025-01-01', '2025-12-31') AS KQ;
-- Đơn chỉ 60k < 200k → không giảm
-- Mong đợi: 18000.00 (chỉ tính voucher 900)

-- case 7: 2 voucher 1 đơn
INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
VALUES (905, '2026-06-01', N'Giảm 20%', N'Đơn tối thiểu 50k', 20, 502, 103);
SELECT dbo.fn_TongTienTietKiemTuVoucher(103, '2025-01-01', '2025-12-31') AS KQ;
-- Tính: 80,000 * 20% + 80,000*20% = 32,000
-- Mong đợi: 32000.00

select * from voucher;
select * from orders;

-- case 8
SELECT dbo.fn_TongTienTietKiemTuVoucher(102, '2026-01-01', '2026-12-31') AS KQ;
-- 👉 Mong đợi: 0.00 (không có đơn áp dụng voucher nào)

-- case 9: update theo dữ liệu chính thức
--UPDATE VOUCHER SET order_ID = 501 WHERE voucher_ID = 902;  -- Freeship
--UPDATE VOUCHER SET customer_ID = 102 WHERE voucher_ID = 902;

SELECT dbo.fn_TongTienTietKiemTuVoucher(102, '2025-01-01', '2025-12-31') AS KQ;
-- Tổng: giảm 18,000 (60,000*30%) + freeship: 10,000 = 28,000
-- Mong đợi: 28000.00

-----------------------------------------------------------
-- REGION 7.5: UPDATE + DELETE ORDER
-----------------------------------------------------------
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
