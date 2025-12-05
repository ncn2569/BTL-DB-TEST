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
-- REGION 3: DỮ LIỆU MẪU BAN ĐẦU
-----------------------------------------------------------
INSERT INTO USERS (ID, Ho_ten, Email, SDT, Password, TKNH, Dia_chi, vai_tro) VALUES
-- ADMIN (1–10)
(1,  N'Nguyễn Văn A', 'admin1@system.com', '0901111111', 'Adm@1234', '111111111111', N'Hà Nội', 'ADMIN'),
(2,  N'Lê Thị B', 'admin2@system.com', '0902222222', 'Adm@1234', '222222222222', N'Hồ Chí Minh', 'ADMIN'),
(3,  N'Phạm Văn C', 'admin3@system.com', '0903333333', 'Adm@1234', '333333333333', N'Đà Nẵng', 'ADMIN'),
(4,  N'Hoàng Thị D', 'admin4@system.com', '0904444444', 'Adm@1234', '444444444444', N'Cần Thơ', 'ADMIN'),
(5,  N'Ngô Thị E', 'admin5@system.com', '0905555555', 'Adm@1234', '555555555555', N'Hải Phòng', 'ADMIN'),
(6,  N'Vũ Văn F', 'admin6@system.com', '0906666666', 'Adm@1234', '666666666666', N'Bình Dương', 'ADMIN'),
(7,  N'Trương Thị G', 'admin7@system.com', '0907777777', 'Adm@1234', '777777777777', N'Quảng Ninh', 'ADMIN'),
(8,  N'Đào Văn H', 'admin8@system.com', '0908888888', 'Adm@1234', '888888888888', N'Nghệ An', 'ADMIN'),

-- CUSTOMER (100–199)
(101, N'Lê Minh Hùng', 'c101@email.com', '0901010101', 'Cus@1234', '101101101101', N'Quận 1, TP.HCM', 'CUSTOMER'),
(102, N'Nguyễn Thị Trang', 'c102@email.com', '0902020202', 'Cus@1234', '102102102102', N'Quận 5, TP.HCM', 'CUSTOMER'),
(103, N'Phạm Quốc Thái', 'c103@email.com', '0903030303', 'Cus@1234', '103103103103', N'Hà Nội', 'CUSTOMER'),
(104, N'Vũ Thị Hoa', 'c104@email.com', '0904040404', 'Cus@1234', '104104104104', N'Cần Thơ', 'CUSTOMER'),
(105, N'Bùi Văn Lâm', 'c105@email.com', '0905050505', 'Cus@1234', '105105105105', N'Đà Nẵng', 'CUSTOMER'),
(106, N'Trần Văn Sáu', 'c106@email.com', '0906060606', 'Cus@1234', '106106106106', N'Quận 7, TP.HCM', 'CUSTOMER'),
(107, N'Đặng Thị Thu', 'c107@email.com', '0907070707', 'Cus@1234', '107107107107', N'Quận Ba Đình, Hà Nội', 'CUSTOMER'),
(108, N'Nguyễn Đức Phát', 'c108@email.com', '0908080808', 'Cus@1234', '108108108108', N'TP Thủ Đức, TP.HCM', 'CUSTOMER'),
(109, N'Hoàng Anh Thư', 'c109@email.com', '0909090909', 'Cus@1234', '109109109109', N'Quận Hải Châu, Đà Nẵng', 'CUSTOMER'),
(110, N'Lý Văn Hào', 'c110@email.com', '0910101010', 'Cus@1234', '110110110110', N'Quận Ninh Kiều, Cần Thơ', 'CUSTOMER'),
(111, N'Phan Thị Kiều', 'c111@email.com', '0911111111', 'Cus@1234', '111111111111', N'Quận Hoàn Kiếm, Hà Nội', 'CUSTOMER'),
(112, N'Võ Trọng Tấn', 'c112@email.com', '0912121212', 'Cus@1234', '112112112112', N'Quận 3, TP.HCM', 'CUSTOMER'),
(113, N'Lê Minh Trí', 'c113@email.com', '0913131313', 'Cus@1234', '113113113113', N'Quận Ngũ Hành Sơn, Đà Nẵng', 'CUSTOMER'),
(114, N'Nguyễn Ngọc Diệp', 'c114@email.com', '0914141414', 'Cus@1234', '114114114114', N'Quận Cái Răng, Cần Thơ', 'CUSTOMER'),
(115, N'Hồ Văn Luyện', 'c115@email.com', '0915151515', 'Cus@1234', '115115115115', N'Quận Tây Hồ, Hà Nội', 'CUSTOMER'),
(116, N'Mai Thị Huệ', 'c116@email.com', '0916161616', 'Cus@1234', '116116116116', N'Quận Phú Nhuận, TP.HCM', 'CUSTOMER'),
(117, N'Dương Quang Vinh', 'c117@email.com', '0917171717', 'Cus@1234', '117117117117', N'Quận Sơn Trà, Đà Nẵng', 'CUSTOMER'),
(118, N'Trần Anh Tuấn', 'c118@email.com', '0918181818', 'Cus@1234', '118118118118', N'Quận Đống Đa, Hà Nội', 'CUSTOMER'),
(119, N'Nguyễn Thanh Tuyền', 'c119@email.com', '0919191919', 'Cus@1234', '119119119119', N'Quận Tân Bình, TP.HCM', 'CUSTOMER'),
(120, N'Phạm Văn Lợi', 'c120@email.com', '0920202020', 'Cus@1234', '120120120120', N'Quận Liên Chiểu, Đà Nẵng', 'CUSTOMER'),
(121, N'Vũ Thị Hồng', 'c121@email.com', '0921212121', 'Cus@1234', '121121121121', N'Quận Long Biên, Hà Nội', 'CUSTOMER'),
(122, N'Bùi Quang Trung', 'c122@email.com', '0922222222', 'Cus@1234', '122122122122', N'Quận Bình Thạnh, TP.HCM', 'CUSTOMER'),
(123, N'Lý Hoàng Nam', 'c123@email.com', '0923232323', 'Cus@1234', '123123123123', N'Quận Cẩm Lệ, Đà Nẵng', 'CUSTOMER'),
(124, N'Đỗ Thị Mai', 'c124@email.com', '0924242424', 'Cus@1234', '124124124124', N'Quận Nam Từ Liêm, Hà Nội', 'CUSTOMER'),
(125, N'Nguyễn Quốc Việt', 'c125@email.com', '0925252525', 'Cus@1234', '125125125125', N'Quận Gò Vấp, TP.HCM', 'CUSTOMER'),
(126, N'Hồ Thị Minh', 'c126@email.com', '0926262626', 'Cus@1234', '126126126126', N'Quận Thanh Khê, Đà Nẵng', 'CUSTOMER'),
(127, N'Trần Văn Quý', 'c127@email.com', '0927272727', 'Cus@1234', '127127127127', N'Quận Hoàng Mai, Hà Nội', 'CUSTOMER'),
(128, N'Vũ Thị Phương', 'c128@email.com', '0928282828', 'Cus@1234', '128128128128', N'Quận Tân Phú, TP.HCM', 'CUSTOMER'),
(129, N'Phan Công Sơn', 'c129@email.com', '0929292929', 'Cus@1234', '129129129129', N'Quận Sơn Trà, Đà Nẵng', 'CUSTOMER'),
(130, N'Lê Văn Thắng', 'c130@email.com', '0930303030', 'Cus@1234', '130130130130', N'Quận Hà Đông, Hà Nội', 'CUSTOMER'),
(131, N'Nguyễn Thị Tuyết', 'c131@email.com', '0931313131', 'Cus@1234', '131131131131', N'Quận 12, TP.HCM', 'CUSTOMER'),
(132, N'Đinh Văn Hải', 'c132@email.com', '0932323232', 'Cus@1234', '132132132132', N'Quận Hải Châu, Đà Nẵng', 'CUSTOMER'),
(133, N'Bùi Văn Kiên', 'c133@email.com', '0933333333', 'Cus@1234', '133133133133', N'Quận Cầu Giấy, Hà Nội', 'CUSTOMER'),
(134, N'Trần Thị Ngọc', 'c134@email.com', '0934343434', 'Cus@1234', '134134134134', N'Quận Bình Tân, TP.HCM', 'CUSTOMER'),
(135, N'Hồ Quang Hiếu', 'c135@email.com', '0935353535', 'Cus@1234', '135135135135', N'Quận Ngũ Hành Sơn, Đà Nẵng', 'CUSTOMER'),
(136, N'Phạm Văn Tài', 'c136@email.com', '0936363636', 'Cus@1234', '136136136136', N'Quận Thanh Xuân, Hà Nội', 'CUSTOMER'),
(137, N'Lê Thị Hương', 'c137@email.com', '0937373737', 'Cus@1234', '137137137137', N'Huyện Bình Chánh, TP.HCM', 'CUSTOMER'),
(138, N'Nguyễn Văn An', 'c138@email.com', '0938383838', 'Cus@1234', '138138138138', N'Quận Cẩm Lệ, Đà Nẵng', 'CUSTOMER'),
(139, N'Vũ Thị Hồng', 'c139@email.com', '0939393939', 'Cus@1234', '139139139139', N'Quận Ba Đình, Hà Nội', 'CUSTOMER'),
(140, N'Bùi Minh Thuận', 'c140@email.com', '0940404040', 'Cus@1234', '140140140140', N'Huyện Hóc Môn, TP.HCM', 'CUSTOMER'),
(141, N'Trần Văn Hùng', 'c141@email.com', '0941414141', 'Cus@1234', '141141141141', N'Quận Liên Chiểu, Đà Nẵng', 'CUSTOMER'),
(142, N'Ngô Thị Thảo', 'c142@email.com', '0942424242', 'Cus@1234', '142142142142', N'Quận Hoàn Kiếm, Hà Nội', 'CUSTOMER'),
(143, N'Phạm Quang Huy', 'c143@email.com', '0943434343', 'Cus@1234', '143143143143', N'Quận 1, TP.HCM', 'CUSTOMER'),
(144, N'Lê Thị Hằng', 'c144@email.com', '0944444444', 'Cus@1234', '144144144144', N'Quận Hải Châu, Đà Nẵng', 'CUSTOMER'),
(145, N'Đặng Văn Tám', 'c145@email.com', '0945454545', 'Cus@1234', '145145145145', N'Quận Tây Hồ, Hà Nội', 'CUSTOMER'),
(146, N'Vũ Văn Sỹ', 'c146@email.com', '0946464646', 'Cus@1234', '146146146146', N'Quận Bình Thạnh, TP.HCM', 'CUSTOMER'),
(147, N'Hồ Thị Trúc', 'c147@email.com', '0947474747', 'Cus@1234', '147147147147', N'Quận Cẩm Lệ, Đà Nẵng', 'CUSTOMER'),
(148, N'Trần Minh Khang', 'c148@email.com', '0948484848', 'Cus@1234', '148148148148', N'Quận Long Biên, Hà Nội', 'CUSTOMER'),
(149, N'Nguyễn Thanh Hải', 'c149@email.com', '0949494949', 'Cus@1234', '149149149149', N'Quận 5, TP.HCM', 'CUSTOMER'),
(150, N'Phạm Thị Yến', 'c150@email.com', '0950505050', 'Cus@1234', '150150150150', N'Quận Thanh Khê, Đà Nẵng', 'CUSTOMER'),
(151, N'Lê Văn Hiếu', 'c151@email.com', '0951515151', 'Cus@1234', '151151151151', N'Quận Hoàng Mai, Hà Nội', 'CUSTOMER'),
(152, N'Đặng Văn Trung', 'c152@email.com', '0952525252', 'Cus@1234', '152152152152', N'Quận Tân Phú, TP.HCM', 'CUSTOMER'),
(153, N'Vũ Thị Hà', 'c153@email.com', '0953535353', 'Cus@1234', '153153153153', N'Quận Sơn Trà, Đà Nẵng', 'CUSTOMER'),
(154, N'Nguyễn Văn Nam', 'c154@email.com', '0954545454', 'Cus@1234', '154154154154', N'Quận Hà Đông, Hà Nội', 'CUSTOMER'),
(155, N'Hồ Thị Lan', 'c155@email.com', '0955555555', 'Cus@1234', '155155155155', N'Quận 12, TP.HCM', 'CUSTOMER'),
(156, N'Trần Văn Long', 'c156@email.com', '0956565656', 'Cus@1234', '156156156156', N'Quận 7, TP.HCM', 'CUSTOMER'),
(157, N'Đinh Thị Yến', 'c157@email.com', '0957575757', 'Cus@1234', '157157157157', N'Quận Ba Đình, Hà Nội', 'CUSTOMER'),
(158, N'Nguyễn Đức Anh', 'c158@email.com', '0958585858', 'Cus@1234', '158158158158', N'TP Thủ Đức, TP.HCM', 'CUSTOMER'),
(159, N'Hoàng Anh Dũng', 'c159@email.com', '0959595959', 'Cus@1234', '159159159159', N'Quận Hải Châu, Đà Nẵng', 'CUSTOMER'),
(160, N'Lý Văn Thanh', 'c160@email.com', '0960606060', 'Cus@1234', '160160160160', N'Quận Ninh Kiều, Cần Thơ', 'CUSTOMER'),
(161, N'Phan Thị Lan', 'c161@email.com', '0961616161', 'Cus@1234', '161161161161', N'Quận Hoàn Kiếm, Hà Nội', 'CUSTOMER'),
(162, N'Võ Trọng Nghĩa', 'c162@email.com', '0962626262', 'Cus@1234', '162162162162', N'Quận 3, TP.HCM', 'CUSTOMER'),
(163, N'Lê Minh Trí', 'c163@email.com', '0963636363', 'Cus@1234', '163163163163', N'Quận Ngũ Hành Sơn, Đà Nẵng', 'CUSTOMER'),
(164, N'Nguyễn Ngọc Mai', 'c164@email.com', '0964646464', 'Cus@1234', '164164164164', N'Quận Cái Răng, Cần Thơ', 'CUSTOMER'),
(165, N'Hồ Văn Hùng', 'c165@email.com', '0965656565', 'Cus@1234', '165165165165', N'Quận Tây Hồ, Hà Nội', 'CUSTOMER'),
(166, N'Mai Thị Loan', 'c166@email.com', '0966666666', 'Cus@1234', '166166166166', N'Quận Phú Nhuận, TP.HCM', 'CUSTOMER'),
(167, N'Dương Quang Hải', 'c167@email.com', '0967676767', 'Cus@1234', '167167167167', N'Quận Sơn Trà, Đà Nẵng', 'CUSTOMER'),
(168, N'Trần Anh Hùng', 'c168@email.com', '0968686868', 'Cus@1234', '168168168168', N'Quận Đống Đa, Hà Nội', 'CUSTOMER'),
(169, N'Nguyễn Thanh Thúy', 'c169@email.com', '0969696969', 'Cus@1234', '169169169169', N'Quận Tân Bình, TP.HCM', 'CUSTOMER'),
(170, N'Phạm Văn Sơn', 'c170@email.com', '0970707070', 'Cus@1234', '170170170170', N'Quận Liên Chiểu, Đà Nẵng', 'CUSTOMER'),
(171, N'Vũ Thị Hà', 'c171@email.com', '0971717171', 'Cus@1234', '171171171171', N'Quận Long Biên, Hà Nội', 'CUSTOMER'),
(172, N'Bùi Quang Vinh', 'c172@email.com', '0972727272', 'Cus@1234', '172172172172', N'Quận Bình Thạnh, TP.HCM', 'CUSTOMER'),
(173, N'Lý Hoàng Long', 'c173@email.com', '0973737373', 'Cus@1234', '173173173173', N'Quận Cẩm Lệ, Đà Nẵng', 'CUSTOMER'),
(174, N'Đỗ Thị Trang', 'c174@email.com', '0974747474', 'Cus@1234', '174174174174', N'Quận Nam Từ Liêm, Hà Nội', 'CUSTOMER'),
(175, N'Nguyễn Quốc Anh', 'c175@email.com', '0975757575', 'Cus@1234', '175175175175', N'Quận Gò Vấp, TP.HCM', 'CUSTOMER'),
(176, N'Hồ Thị Hiền', 'c176@email.com', '0976767676', 'Cus@1234', '176176176176', N'Quận Thanh Khê, Đà Nẵng', 'CUSTOMER'),
(177, N'Trần Văn Mạnh', 'c177@email.com', '0977777777', 'Cus@1234', '177177177177', N'Quận Hoàng Mai, Hà Nội', 'CUSTOMER'),
(178, N'Vũ Thị Yến', 'c178@email.com', '0978787878', 'Cus@1234', '178178178178', N'Quận Tân Phú, TP.HCM', 'CUSTOMER'),
(179, N'Phan Công Tuấn', 'c179@email.com', '0979797979', 'Cus@1234', '179179179179', N'Quận Sơn Trà, Đà Nẵng', 'CUSTOMER'),
(180, N'Lê Văn Quang', 'c180@email.com', '0980808080', 'Cus@1234', '180180180180', N'Quận Hà Đông, Hà Nội', 'CUSTOMER'),
(181, N'Nguyễn Thị Thu', 'c181@email.com', '0981818181', 'Cus@1234', '181181181181', N'Quận 12, TP.HCM', 'CUSTOMER'),
(182, N'Đinh Văn Nam', 'c182@email.com', '0982828282', 'Cus@1234', '182182182182', N'Quận Hải Châu, Đà Nẵng', 'CUSTOMER'),
(183, N'Bùi Văn Phúc', 'c183@email.com', '0983838383', 'Cus@1234', '183183183183', N'Quận Cầu Giấy, Hà Nội', 'CUSTOMER'),
(184, N'Trần Thị Hiền', 'c184@email.com', '0984848484', 'Cus@1234', '184184184184', N'Quận Bình Tân, TP.HCM', 'CUSTOMER'),
(185, N'Hồ Quang Huy', 'c185@email.com', '0985858585', 'Cus@1234', '185185185185', N'Quận Ngũ Hành Sơn, Đà Nẵng', 'CUSTOMER'),
(186, N'Phạm Văn Khoa', 'c186@email.com', '0986868686', 'Cus@1234', '186186186186', N'Quận Thanh Xuân, Hà Nội', 'CUSTOMER'),
(187, N'Lê Thị Hương Giang', 'c187@email.com', '0987878787', 'Cus@1234', '187187187187', N'Huyện Bình Chánh, TP.HCM', 'CUSTOMER'),
(188, N'Nguyễn Văn Quang', 'c188@email.com', '0988888888', 'Cus@1234', '188188188188', N'Quận Cẩm Lệ, Đà Nẵng', 'CUSTOMER'),
(189, N'Vũ Thị Lan', 'c189@email.com', '0989898989', 'Cus@1234', '189189189189', N'Quận Ba Đình, Hà Nội', 'CUSTOMER'),
(190, N'Bùi Minh Đức', 'c190@email.com', '0990909090', 'Cus@1234', '190190190190', N'Huyện Hóc Môn, TP.HCM', 'CUSTOMER'),

-- RESTAURANT (200–299)
(201, N'Hủ Tiếu Thanh Xuân', 'r201@restaurant.com', '0902100210', 'Res@1234', '201201201201', N'Quận 1, TP.HCM', 'RESTAURANT'),
(202, N'Cơm Tấm Ba Ghiền', 'r202@restaurant.com', '0902200220', 'Res@1234', '202202202202', N'Đà Nẵng', 'RESTAURANT'),
(203, N'Phở Huỳnh Mai', 'r203@restaurant.com', '0902300230', 'Res@1234', '203203203203', N'Huế', 'RESTAURANT'),
(204, N'Lẩu Bò Bà Sáu', 'r204@restaurant.com', '0902400240', 'Res@1234', '204204204204', N'Cần Thơ', 'RESTAURANT'),
(205, N'Phúc Long', 'r205@restaurant.com', '0902500250', 'Res@1234', '205205205205', N'Hà Nội', 'RESTAURANT'),
(206, N'Bún Chả Hương Liên', 'r206@restaurant.com', '0902600260', 'Res@1234', '206206206206', N'Quận Cầu Giấy, Hà Nội', 'RESTAURANT'),
(207, N'Bún Đậu Mắm Tôm Mộc', 'r207@restaurant.com', '0902700270', 'Res@1234', '207207207207', N'Quận 3, TP.HCM', 'RESTAURANT'),
(208, N'Món Huế Cố Đô', 'r208@restaurant.com', '0902800280', 'Res@1234', '208208208208', N'Quận Hải Châu, Đà Nẵng', 'RESTAURANT'),
(209, N'Chè Thái Cần Thơ', 'r209@restaurant.com', '0902900290', 'Res@1234', '209209209209', N'Quận Ninh Kiều, Cần Thơ', 'RESTAURANT'),
(210, N'Gà Rán KFC', 'r210@restaurant.com', '0910000000', 'Res@1234', '210210210210', N'Quận Hoàn Kiếm, Hà Nội', 'RESTAURANT'),
(211, N'Pizza P', 'r211@restaurant.com', '0911000000', 'Res@1234', '211211211211', N'Quận 1, TP.HCM', 'RESTAURANT'),
(212, N'Cơm Niêu Sài Gòn', 'r212@restaurant.com', '0912000000', 'Res@1234', '212212212212', N'Quận 5, TP.HCM', 'RESTAURANT'),
(213, N'Bánh Xèo Tôm Nhảy', 'r213@restaurant.com', '0913000000', 'Res@1234', '213213213213', N'Huế', 'RESTAURANT'),
(214, N'Kem Fanny', 'r214@restaurant.com', '0914000000', 'Res@1234', '214214214214', N'Đà Nẵng', 'RESTAURANT'),
(215, N'Mì Cay Seoul', 'r215@restaurant.com', '0915000000', 'Res@1234', '215215215215', N'Quận Thanh Xuân, Hà Nội', 'RESTAURANT'),
(216, N'Buffet Lẩu Phan', 'r216@restaurant.com', '0916000000', 'Res@1234', '216216216216', N'Quận Đống Đa, Hà Nội', 'RESTAURANT'),
(217, N'Hải Sản Biển Đông', 'r217@restaurant.com', '0917000000', 'Res@1234', '217217217217', N'Quận 7, TP.HCM', 'RESTAURANT'),
(218, N'Cháo Lòng Bà Tám', 'r218@restaurant.com', '0918000000', 'Res@1234', '218218218218', N'Đà Nẵng', 'RESTAURANT'),
(219, N'Cafe Highland', 'r219@restaurant.com', '0919000000', 'Res@1234', '219219219219', N'Cần Thơ', 'RESTAURANT'),
(220, N'Trà Sữa ToCoToCo', 'r220@restaurant.com', '0920000000', 'Res@1234', '220220220220', N'Quận Ba Đình, Hà Nội', 'RESTAURANT'),
(221, N'Bánh Bột Lọc Huế', 'r221@restaurant.com', '0921000000', 'Res@1234', '221221221221', N'Huế', 'RESTAURANT'),
(222, N'Sushi Kei', 'r222@restaurant.com', '0922000000', 'Res@1234', '222222222222', N'Quận 1, TP.HCM', 'RESTAURANT'),
(223, N'Mì Ý Sốt Kem', 'r223@restaurant.com', '0923000000', 'Res@1234', '223223223223', N'Quận 4, TP.HCM', 'RESTAURANT'),
(224, N'Bánh Canh Cua', 'r224@restaurant.com', '0924000000', 'Res@1234', '224224224224', N'Đà Nẵng', 'RESTAURANT'),
(225, N'Dimsum Đại Hỷ', 'r225@restaurant.com', '0925000000', 'Res@1234', '225225225225', N'Quận Hà Đông, Hà Nội', 'RESTAURANT'),
(226, N'Chè Khúc Bạch', 'r226@restaurant.com', '0926000000', 'Res@1234', '226226226226', N'Quận Long Biên, Hà Nội', 'RESTAURANT'),
(227, N'Bún Riêu Cua', 'r227@restaurant.com', '0927000000', 'Res@1234', '227227227227', N'Quận 10, TP.HCM', 'RESTAURANT'),
(228, N'Cơm Gà Xối Mỡ', 'r228@restaurant.com', '0928000000', 'Res@1234', '228228228228', N'Quận Tân Bình, TP.HCM', 'RESTAURANT'),
(229, N'Thịt Heo Hai Da', 'r229@restaurant.com', '0929000000', 'Res@1234', '229229229229', N'Cần Thơ', 'RESTAURANT'),
(230, N'Bánh Ướt Lòng Gà', 'r230@restaurant.com', '0930000000', 'Res@1234', '230230230230', N'Huế', 'RESTAURANT'),
(231, N'Kem Swensens', 'r231@restaurant.com', '0931000000', 'Res@1234', '231231231231', N'Quận 1, TP.HCM', 'RESTAURANT'),
(232, N'Phở Cuốn', 'r232@restaurant.com', '0932000000', 'Res@1234', '232232232232', N'Hà Nội', 'RESTAURANT'),
(233, N'Bún Bò Huế Ông Thi', 'r233@restaurant.com', '0933000000', 'Res@1234', '233233233233', N'Quận 5, TP.HCM', 'RESTAURANT'),
(234, N'Súp Cua', 'r234@restaurant.com', '0934000000', 'Res@1234', '234234234234', N'Đà Nẵng', 'RESTAURANT'),
(235, N'Hủ Tiếu Nam Vang', 'r235@restaurant.com', '0935000000', 'Res@1234', '235235235235', N'Cần Thơ', 'RESTAURANT'),
(236, N'Trà Lipton', 'r236@restaurant.com', '0936000000', 'Res@1234', '236236236236', N'Hà Nội', 'RESTAURANT'),
(237, N'Bò Né', 'r237@restaurant.com', '0937000000', 'Res@1234', '237237237237', N'Quận Gò Vấp, TP.HCM', 'RESTAURANT'),
(238, N'Cà Phê Trung Nguyên', 'r238@restaurant.com', '0938000000', 'Res@1234', '238238238238', N'Quận 3, TP.HCM', 'RESTAURANT'),
(239, N'Nước Ép Trái Cây', 'r239@restaurant.com', '0939000000', 'Res@1234', '239239239239', N'Đà Nẵng', 'RESTAURANT'),
(240, N'Bún Mọc', 'r240@restaurant.com', '0940000000', 'Res@1234', '240240240240', N'Huế', 'RESTAURANT'),
(241, N'Lẩu Mắm', 'r241@restaurant.com', '0941000000', 'Res@1234', '241241241241', N'Cần Thơ', 'RESTAURANT'),
(242, N'Bánh Tét', 'r242@restaurant.com', '0942000000', 'Res@1234', '242242242242', N'Hà Nội', 'RESTAURANT'),
(243, N'Bánh Chưng', 'r243@restaurant.com', '0943000000', 'Res@1234', '243243243243', N'Quận 1, TP.HCM', 'RESTAURANT'),
(244, N'Thịt Kho Trứng', 'r244@restaurant.com', '0944000000', 'Res@1234', '244244244244', N'Quận Tân Bình, TP.HCM', 'RESTAURANT'),
(245, N'Canh Chua', 'r245@restaurant.com', '0945000000', 'Res@1234', '245245245245', N'Đà Nẵng', 'RESTAURANT'),
(246, N'Cá Kho Tộ', 'r246@restaurant.com', '0946000000', 'Res@1234', '246246246246', N'Huế', 'RESTAURANT'),
(247, N'Gỏi Cuốn', 'r247@restaurant.com', '0947000000', 'Res@1234', '247247247247', N'Cần Thơ', 'RESTAURANT'),
(248, N'Chả Giò', 'r248@restaurant.com', '0948000000', 'Res@1234', '248248248248', N'Hà Nội', 'RESTAURANT'),
(249, N'Sữa Chua', 'r249@restaurant.com', '0949000000', 'Res@1234', '249249249249', N'Quận 5, TP.HCM', 'RESTAURANT'),
(250, N'Bánh Đúc', 'r250@restaurant.com', '0950000000', 'Res@1234', '250250250250', N'Quận 1, TP.HCM', 'RESTAURANT'),
(251, N'Bánh Phồng Tôm', 'r251@restaurant.com', '0951000000', 'Res@1234', '251251251251', N'Đà Nẵng', 'RESTAURANT'),
(252, N'Cà Phê Sữa', 'r252@restaurant.com', '0952000000', 'Res@1234', '252252252252', N'Huế', 'RESTAURANT'),
(253, N'Bánh Quy', 'r253@restaurant.com', '0953000000', 'Res@1234', '253253253253', N'Cần Thơ', 'RESTAURANT'),
(254, N'Bánh Kem', 'r254@restaurant.com', '0954000000', 'Res@1234', '254254254254', N'Hà Nội', 'RESTAURANT'),
(255, N'Sữa Tươi', 'r255@restaurant.com', '0955000000', 'Res@1234', '255255255255', N'Quận Gò Vấp, TP.HCM', 'RESTAURANT'),

-- SHIPPER (300–399)
(301, N'Tài Xế Minh', 's301@shipper.com', '0903100310', 'Shi@1234', '301301301301', N'Hà Nội', 'SHIPPER'),
(302, N'Tài Xế Nam', 's302@shipper.com', '0903200320', 'Shi@1234', '302302302302', N'TP.HCM', 'SHIPPER'),
(303, N'Tài Xế Linh', 's303@shipper.com', '0903300330', 'Shi@1234', '303303303303', N'Cần Thơ', 'SHIPPER'),
(304, N'Tài Xế Hưng', 's304@shipper.com', '0903400340', 'Shi@1234', '304304304304', N'Đà Nẵng', 'SHIPPER'),
(305, N'Tài Xế Phát', 's305@shipper.com', '0903500350', 'Shi@1234', '305305305305', N'Huế', 'SHIPPER'),
(306, N'Tài Xế Tài', 's306@shipper.com', '0903600360', 'Shi@1234', '306306306306', N'Hà Nội', 'SHIPPER'),
(307, N'Tài Xế Sơn', 's307@shipper.com', '0903700370', 'Shi@1234', '307307307307', N'TP.HCM', 'SHIPPER'),
(308, N'Tài Xế Hiếu', 's308@shipper.com', '0903800380', 'Shi@1234', '308308308308', N'Cần Thơ', 'SHIPPER'),
(309, N'Tài Xế Mạnh', 's309@shipper.com', '0903900390', 'Shi@1234', '309309309309', N'Đà Nẵng', 'SHIPPER'),
(310, N'Tài Xế Tuấn', 's310@shipper.com', '0910000000', 'Shi@1234', '310310310310', N'Huế', 'SHIPPER'),
(311, N'Tài Xế Việt', 's311@shipper.com', '0911000000', 'Shi@1234', '311311311311', N'Hà Nội', 'SHIPPER'),
(312, N'Tài Xế Anh', 's312@shipper.com', '0912000000', 'Shi@1234', '312312312312', N'TP.HCM', 'SHIPPER'),
(313, N'Tài Xế Tùng', 's313@shipper.com', '0913000000', 'Shi@1234', '313313313313', N'Cần Thơ', 'SHIPPER'),
(314, N'Tài Xế Lộc', 's314@shipper.com', '0914000000', 'Shi@1234', '314314314314', N'Đà Nẵng', 'SHIPPER'),
(315, N'Tài Xế Hải', 's315@shipper.com', '0915000000', 'Shi@1234', '315315315315', N'Huế', 'SHIPPER'),
(316, N'Tài Xế Khoa', 's316@shipper.com', '0916000000', 'Shi@1234', '316316316316', N'Hà Nội', 'SHIPPER'),
(317, N'Tài Xế Nam', 's317@shipper.com', '0917000000', 'Shi@1234', '317317317317', N'TP.HCM', 'SHIPPER'),
(318, N'Tài Xế Dũng', 's318@shipper.com', '0918000000', 'Shi@1234', '318318318318', N'Cần Thơ', 'SHIPPER'),
(319, N'Tài Xế Vinh', 's319@shipper.com', '0919000000', 'Shi@1234', '319319319319', N'Đà Nẵng', 'SHIPPER'),
(320, N'Tài Xế Long', 's320@shipper.com', '0920000000', 'Shi@1234', '320320320320', N'Huế', 'SHIPPER'),
(321, N'Tài Xế Phát', 's321@shipper.com', '0921000000', 'Shi@1234', '321321321321', N'Hà Nội', 'SHIPPER'),
(322, N'Tài Xế Phúc', 's322@shipper.com', '0922000000', 'Shi@1234', '322322322322', N'TP.HCM', 'SHIPPER'),
(323, N'Tài Xế Quý', 's323@shipper.com', '0923000000', 'Shi@1234', '323323323323', N'Cần Thơ', 'SHIPPER'),
(324, N'Tài Xế Trường', 's324@shipper.com', '0924000000', 'Shi@1234', '324324324324', N'Đà Nẵng', 'SHIPPER'),
(325, N'Tài Xế Hùng', 's325@shipper.com', '0925000000', 'Shi@1234', '325325325325', N'Huế', 'SHIPPER'),
(326, N'Tài Xế Lân', 's326@shipper.com', '0926000000', 'Shi@1234', '326326326326', N'Hà Nội', 'SHIPPER'),
(327, N'Tài Xế Quân', 's327@shipper.com', '0927000000', 'Shi@1234', '327327327327', N'TP.HCM', 'SHIPPER'),
(328, N'Tài Xế Thiện', 's328@shipper.com', '0928000000', 'Shi@1234', '328328328328', N'Cần Thơ', 'SHIPPER'),
(329, N'Tài Xế Huy', 's329@shipper.com', '0929000000', 'Shi@1234', '329329329329', N'Đà Nẵng', 'SHIPPER'),
(330, N'Tài Xế Hào', 's330@shipper.com', '0930000000', 'Shi@1234', '330330330330', N'Huế', 'SHIPPER'),
(331, N'Tài Xế Kiên', 's331@shipper.com', '0931000000', 'Shi@1234', '331331331331', N'Hà Nội', 'SHIPPER'),
(332, N'Tài Xế Toàn', 's332@shipper.com', '0932000000', 'Shi@1234', '332332332332', N'TP.HCM', 'SHIPPER'),
(333, N'Tài Xế Thắng', 's333@shipper.com', '0933000000', 'Shi@1234', '333333333333', N'Cần Thơ', 'SHIPPER'),
(334, N'Tài Xế Hòa', 's334@shipper.com', '0934000000', 'Shi@1234', '334334334334', N'Đà Nẵng', 'SHIPPER'),
(335, N'Tài Xế Sỹ', 's335@shipper.com', '0935000000', 'Shi@1234', '335335335335', N'Huế', 'SHIPPER'),
(336, N'Tài Xế Lâm', 's336@shipper.com', '0936000000', 'Shi@1234', '336336336336', N'Hà Nội', 'SHIPPER'),
(337, N'Tài Xế Châu', 's337@shipper.com', '0937000000', 'Shi@1234', '337337337337', N'TP.HCM', 'SHIPPER'),
(338, N'Tài Xế Phương', 's338@shipper.com', '0938000000', 'Shi@1234', '338338338338', N'Cần Thơ', 'SHIPPER'),
(339, N'Tài Xế Trọng', 's339@shipper.com', '0939000000', 'Shi@1234', '339339339339', N'Đà Nẵng', 'SHIPPER'),
(340, N'Tài Xế Thanh', 's340@shipper.com', '0940000000', 'Shi@1234', '340340340340', N'Huế', 'SHIPPER'),
(341, N'Tài Xế Tiến', 's341@shipper.com', '0941000000', 'Shi@1234', '341341341341', N'Hà Nội', 'SHIPPER'),
(342, N'Tài Xế Tình', 's342@shipper.com', '0942000000', 'Shi@1234', '342342342342', N'TP.HCM', 'SHIPPER'),
(343, N'Tài Xế Kiệt', 's343@shipper.com', '0943000000', 'Shi@1234', '343343343343', N'Cần Thơ', 'SHIPPER'),
(344, N'Tài Xế Tấn', 's344@shipper.com', '0944000000', 'Shi@1234', '344344344344', N'Đà Nẵng', 'SHIPPER'),
(345, N'Tài Xế Minh', 's345@shipper.com', '0945000000', 'Shi@1234', '345345345345', N'Huế', 'SHIPPER'),
(346, N'Tài Xế Vương', 's346@shipper.com', '0946000000', 'Shi@1234', '346346346346', N'Hà Nội', 'SHIPPER'),
(347, N'Tài Xế Giang', 's347@shipper.com', '0947000000', 'Shi@1234', '347347347347', N'TP.HCM', 'SHIPPER'),
(348, N'Tài Xế Bảo', 's348@shipper.com', '0948000000', 'Shi@1234', '348348348348', N'Cần Thơ', 'SHIPPER'),
(349, N'Tài Xế Hoàng', 's349@shipper.com', '0949000000', 'Shi@1234', '349349349349', N'Đà Nẵng', 'SHIPPER'),
(350, N'Tài Xế Hợp', 's350@shipper.com', '0950000000', 'Shi@1234', '350350350350', N'Huế', 'SHIPPER'),
(351, N'Tài Xế Quang', 's351@shipper.com', '0951000000', 'Shi@1234', '351351351351', N'Hà Nội', 'SHIPPER'),
(352, N'Tài Xế Hạnh', 's352@shipper.com', '0952000000', 'Shi@1234', '352352352352', N'TP.HCM', 'SHIPPER'),
(353, N'Tài Xế Lượng', 's353@shipper.com', '0953000000', 'Shi@1234', '353353353353', N'Cần Thơ', 'SHIPPER'),
(354, N'Tài Xế Bách', 's354@shipper.com', '0954000000', 'Shi@1234', '354354354354', N'Đà Nẵng', 'SHIPPER'),
(355, N'Tài Xế Linh', 's355@shipper.com', '0955000000', 'Shi@1234', '355355355355', N'Huế', 'SHIPPER'),
(356, N'Tài Xế Phong', 's356@shipper.com', '0956000000', 'Shi@1234', '356356356356', N'Hà Nội', 'SHIPPER'),
(357, N'Tài Xế Ngọc', 's357@shipper.com', '0957000000', 'Shi@1234', '357357357357', N'TP.HCM', 'SHIPPER'),
(358, N'Tài Xế Cường', 's358@shipper.com', '0958000000', 'Shi@1234', '358358358358', N'Cần Thơ', 'SHIPPER'),
(359, N'Tài Xế Phương', 's359@shipper.com', '0959000000', 'Shi@1234', '359359359359', N'Đà Nẵng', 'SHIPPER'),
(360, N'Tài Xế Trâm', 's360@shipper.com', '0960000000', 'Shi@1234', '360360360360', N'Huế', 'SHIPPER'),
(361, N'Tài Xế Chung', 's361@shipper.com', '0961000000', 'Shi@1234', '361361361361', N'Hà Nội', 'SHIPPER'),
(362, N'Tài Xế Hoài', 's362@shipper.com', '0962000000', 'Shi@1234', '362362362362', N'TP.HCM', 'SHIPPER'),
(363, N'Tài Xế Luận', 's363@shipper.com', '0963000000', 'Shi@1234', '363363363363', N'Cần Thơ', 'SHIPPER'),
(364, N'Tài Xế Hiền', 's364@shipper.com', '0964000000', 'Shi@1234', '364364364364', N'Đà Nẵng', 'SHIPPER'),
(365, N'Tài Xế Phi', 's365@shipper.com', '0965000000', 'Shi@1234', '365365365365', N'Huế', 'SHIPPER'),
(366, N'Tài Xế Dũng', 's366@shipper.com', '0966000000', 'Shi@1234', '366366366366', N'Hà Nội', 'SHIPPER'),
(367, N'Tài Xế Trí', 's367@shipper.com', '0967000000', 'Shi@1234', '367367367367', N'TP.HCM', 'SHIPPER'),
(368, N'Tài Xế Lợi', 's368@shipper.com', '0968000000', 'Shi@1234', '368368368368', N'Cần Thơ', 'SHIPPER'),
(369, N'Tài Xế Tình', 's369@shipper.com', '0969000000', 'Shi@1234', '369369369369', N'Đà Nẵng', 'SHIPPER'),
(370, N'Tài Xế Nhân', 's370@shipper.com', '0970000000', 'Shi@1234', '370370370370', N'Huế', 'SHIPPER'),
(371, N'Tài Xế Thuận', 's371@shipper.com', '0971000000', 'Shi@1234', '371371371371', N'Hà Nội', 'SHIPPER'),
(372, N'Tài Xế Mỹ', 's372@shipper.com', '0972000000', 'Shi@1234', '372372372372', N'TP.HCM', 'SHIPPER'),
(373, N'Tài Xế An', 's373@shipper.com', '0973000000', 'Shi@1234', '373373373373', N'Cần Thơ', 'SHIPPER'),
(374, N'Tài Xế Tùng', 's374@shipper.com', '0974000000', 'Shi@1234', '374374374374', N'Đà Nẵng', 'SHIPPER'),
(375, N'Tài Xế Trâm', 's375@shipper.com', '0975000000', 'Shi@1234', '375375375375', N'Huế', 'SHIPPER'),
(376, N'Tài Xế Lễ', 's376@shipper.com', '0976000000', 'Shi@1234', '376376376376', N'Hà Nội', 'SHIPPER'),
(377, N'Tài Xế Thắng', 's377@shipper.com', '0977000000', 'Shi@1234', '377377377377', N'TP.HCM', 'SHIPPER'),
(378, N'Tài Xế Hân', 's378@shipper.com', '0978000000', 'Shi@1234', '378378378378', N'Cần Thơ', 'SHIPPER'),
(379, N'Tài Xế Hào', 's379@shipper.com', '0979000000', 'Shi@1234', '379379379379', N'Đà Nẵng', 'SHIPPER'),
(380, N'Tài Xế Kiên', 's380@shipper.com', '0980000000', 'Shi@1234', '380380380380', N'Huế', 'SHIPPER'),
(381, N'Tài Xế Khoa', 's381@shipper.com', '0981000000', 'Shi@1234', '381381381381', N'Hà Nội', 'SHIPPER'),
(382, N'Tài Xế Duy', 's382@shipper.com', '0982000000', 'Shi@1234', '382382382382', N'TP.HCM', 'SHIPPER'),
(383, N'Tài Xế Lộc', 's383@shipper.com', '0983000000', 'Shi@1234', '383383383383', N'Cần Thơ', 'SHIPPER'),
(384, N'Tài Xế Huy', 's384@shipper.com', '0984000000', 'Shi@1234', '384384384384', N'Đà Nẵng', 'SHIPPER'),
(385, N'Tài Xế Hoàng', 's385@shipper.com', '0985000000', 'Shi@1234', '385385385385', N'Huế', 'SHIPPER'),
(386, N'Tài Xế Đức', 's386@shipper.com', '0986000000', 'Shi@1234', '386386386386', N'Hà Nội', 'SHIPPER'),
(387, N'Tài Xế Khang', 's387@shipper.com', '0987000000', 'Shi@1234', '387387387387', N'TP.HCM', 'SHIPPER'),
(388, N'Tài Xế Danh', 's388@shipper.com', '0988000000', 'Shi@1234', '388388388388', N'Cần Thơ', 'SHIPPER'),
(389, N'Tài Xế Trương', 's389@shipper.com', '0989000000', 'Shi@1234', '389389389389', N'Đà Nẵng', 'SHIPPER'),
(390, N'Tài Xế Sơn', 's390@shipper.com', '0990000000', 'Shi@1234', '390390390390', N'Huế', 'SHIPPER'),
(391, N'Tài Xế Nghĩa', 's391@shipper.com', '0991000000', 'Shi@1234', '391391391391', N'Hà Nội', 'SHIPPER'),
(392, N'Tài Xế Công', 's392@shipper.com', '0992000000', 'Shi@1234', '392392392392', N'TP.HCM', 'SHIPPER'),
(393, N'Tài Xế Lộc', 's393@shipper.com', '0993000000', 'Shi@1234', '393393393393', N'Cần Thơ', 'SHIPPER'),
(394, N'Tài Xế Nam', 's394@shipper.com', '0994000000', 'Shi@1234', '394394394394', N'Đà Nẵng', 'SHIPPER'),
(395, N'Tài Xế Dũng', 's395@shipper.com', '0995000000', 'Shi@1234', '395395395395', N'Huế', 'SHIPPER');

INSERT INTO RESTAURANT (user_ID, Thoi_gian_mo_cua, Thoi_gian_dong_cua, Trang_thai) VALUES
(201, '08:00', '22:00', N'đang hoạt động'),
(202, '07:00', '21:00', N'đang hoạt động'),
(203, '09:00', '21:00', N'đang hoạt động'),
(204, '10:00', '23:00', N'đang hoạt động'),
(205, '06:30', '20:30', N'đang hoạt động'),
(206, '09:00', '21:00', N'đang hoạt động'), 
(207, '08:00', '22:00', N'đang hoạt động'),
(208, '09:30', '22:30', N'đang hoạt động'), 
(209, '10:00', '20:00', N'đang hoạt động'),
(210, '08:00', '23:00', N'đang hoạt động'), 
(211, '11:00', '23:30', N'đang hoạt động'),
(212, '07:30', '21:30', N'đang hoạt động'), 
(213, '10:30', '22:00', N'đang hoạt động'),
(214, '12:00', '21:00', N'đang hoạt động'), 
(215, '08:00', '20:00', N'đang hoạt động'),
(216, '17:00', '23:00', N'đang hoạt động'), 
(217, '09:00', '22:00', N'đang hoạt động'),
(218, '06:00', '14:00', N'đang hoạt động'), 
(219, '06:30', '21:30', N'đang hoạt động'),
(220, '10:00', '22:00', N'đang hoạt động'), 
(221, '11:00', '21:00', N'đang hoạt động'),
(222, '11:30', '22:30', N'đang hoạt động'), 
(223, '10:00', '20:00', N'đang hoạt động'),
(224, '07:00', '19:00', N'đang hoạt động'), 
(225, '10:00', '21:00', N'đang hoạt động'),
(226, '13:00', '22:00', N'đang hoạt động'), 
(227, '09:00', '20:00', N'đang hoạt động'),
(228, '07:00', '23:00', N'đang hoạt động'), 
(229, '10:00', '20:00', N'đang hoạt động'),
(230, '09:00', '18:00', N'đang hoạt động'), 
(231, '10:00', '22:00', N'đang hoạt động'),
(232, '06:00', '14:00', N'đang hoạt động'), 
(233, '08:00', '21:00', N'đang hoạt động'),
(234, '11:00', '23:00', N'đang hoạt động'), 
(235, '09:00', '22:00', N'đang hoạt động'),
(236, '06:00', '18:00', N'đang hoạt động'), 
(237, '10:00', '23:00', N'đang hoạt động'),
(238, '06:00', '17:00', N'đang hoạt động'), 
(239, '07:00', '20:00', N'đang hoạt động'),
(240, '10:00', '21:00', N'đang hoạt động'), 
(241, '11:00', '22:00', N'đang hoạt động'),
(242, '07:00', '20:00', N'đang hoạt động'), 
(243, '07:00', '19:00', N'đang hoạt động'),
(244, '08:00', '21:00', N'đóng cửa'), 
(245, '10:00', '22:00', N'đang hoạt động'),
(246, '11:00', '23:00', N'đang hoạt động'), 
(247, '09:00', '21:00', N'tạm nghỉ'),
(248, '07:00', '18:00', N'đang hoạt động'), 
(249, '12:00', '20:00', N'đang hoạt động'),
(250, '08:00', '22:00', N'đóng cửa'), 
(251, '10:00', '23:00', N'đang hoạt động'),
(252, '07:00', '20:00', N'đang hoạt động'), 
(253, '09:00', '22:00', N'tạm nghỉ'),
(254, '08:00', '21:00', N'đang hoạt động'), 
(255, '07:00', '23:00', N'đang hoạt động');;
INSERT INTO CUSTOMER (user_ID) VALUES
(101), (102), (103), (104), (105), (106), (107), (108), (109), (110), (111), (112), (113), (114), (115),
(116), (117), (118), (119), (120), (121), (122), (123), (124), (125),
(126), (127), (128), (129), (130), (131), (132), (133), (134), (135),
(136), (137), (138), (139), (140), (141), (142), (143), (144), (145),
(146), (147), (148), (149), (150), (151), (152), (153), (154), (155),
(156), (157), (158), (159), (160), (161), (162), (163), (164), (165),
(166), (167), (168), (169), (170), (171), (172), (173), (174), (175),
(176), (177), (178), (179), (180), (181), (182), (183), (184), (185),
(186), (187), (188), (189), (190);
INSERT INTO SHIPPER (user_ID, bien_so_xe, trang_thai) VALUES
(301, '30-A1-12345', N'trực tuyến'),
(302, '30-A2-67890', N'trực tuyến'),
(303, '30-B1-11111', N'trực tuyến'),
(304, '30-B2-22222', N'trực tuyến'),
(305, '30-B3-33333', N'trực tuyến'),
(306, '50-C1-00001', N'trực tuyến'),
(307, '50-C1-00002', N'trực tuyến'),
(308, '50-C1-00003', N'trực tuyến'), 
(309, '50-C1-00004', N'trực tuyến'),
(310, '50-C1-00005', N'trực tuyến'), 
(311, '50-C1-00006', N'trực tuyến'),
(312, '50-C1-00007', N'trực tuyến'), 
(313, '50-C1-00008', N'trực tuyến'),
(314, '50-C1-00009', N'trực tuyến'), 
(315, '50-C1-00010', N'trực tuyến'),
(316, '50-C1-00011', N'trực tuyến'), 
(317, '50-C1-00012', N'trực tuyến'),
(318, '50-C1-00013', N'trực tuyến'), 
(319, '50-C1-00014', N'trực tuyến'),
(320, '50-C1-00015', N'đang bận'), 
(321, '50-C1-00016', N'trực tuyến'),
(322, '50-C1-00017', N'trực tuyến'), 
(323, '50-C1-00018', N'đang bận'),
(324, '50-C1-00019', N'trực tuyến'), 
(325, '50-C1-00020', N'trực tuyến'),
(326, '50-C1-00021', N'đang bận'), 
(327, '50-C1-00022', N'trực tuyến'),
(328, '50-C1-00023', N'trực tuyến'), 
(329, '50-C1-00024', N'đang bận'),
(330, '50-C1-00025', N'trực tuyến'), 
(331, '50-C1-00026', N'trực tuyến'),
(332, '50-C1-00027', N'đang bận'), 
(333, '50-C1-00028', N'trực tuyến'),
(334, '50-C1-00029', N'trực tuyến'), 
(335, '50-C1-00030', N'đang bận'),
(336, '50-C1-00031', N'trực tuyến'), 
(337, '50-C1-00032', N'trực tuyến'),
(338, '50-C1-00033', N'đang bận'), 
(339, '50-C1-00034', N'trực tuyến'),
(340, '50-C1-00035', N'trực tuyến'), 
(341, '50-C1-00036', N'đang bận'),
(342, '50-C1-00037', N'trực tuyến'), 
(343, '50-C1-00038', N'trực tuyến'),
(344, '50-C1-00039', N'đang bận'), 
(345, '50-C1-00040', N'trực tuyến'),
(346, '50-C1-00041', N'trực tuyến'), 
(347, '50-C1-00042', N'đang bận'),
(348, '50-C1-00043', N'trực tuyến'), 
(349, '50-C1-00044', N'trực tuyến'),
(350, '50-C1-00045', N'đang bận'), 
(351, '50-C1-00046', N'trực tuyến'),
(352, '50-C1-00047', N'trực tuyến'), 
(353, '50-C1-00048', N'đang bận'),
(354, '50-C1-00049', N'trực tuyến'), 
(355, '50-C1-00050', N'trực tuyến'),
(356, '50-C1-00051', N'đang bận'), 
(357, '50-C1-00052', N'trực tuyến'),
(358, '50-C1-00053', N'trực tuyến'), 
(359, '50-C1-00054', N'đang bận'),
(360, '50-C1-00055', N'trực tuyến'), 
(361, '50-C1-00056', N'trực tuyến'),
(362, '50-C1-00057', N'đang bận'), 
(363, '50-C1-00058', N'trực tuyến'),
(364, '50-C1-00059', N'trực tuyến'), 
(365, '50-C1-00060', N'đang bận'),
(366, '50-C1-00061', N'trực tuyến'), 
(367, '50-C1-00062', N'trực tuyến'),
(368, '50-C1-00063', N'đang bận'), 
(369, '50-C1-00064', N'trực tuyến'),
(370, '50-C1-00065', N'trực tuyến'), 
(371, '50-C1-00066', N'đang bận'),
(372, '50-C1-00067', N'trực tuyến'), 
(373, '50-C1-00068', N'trực tuyến'),
(374, '50-C1-00069', N'đang bận'), 
(375, '50-C1-00070', N'trực tuyến'),
(376, '50-C1-00071', N'trực tuyến'), 
(377, '50-C1-00072', N'đang bận'),
(378, '50-C1-00073', N'trực tuyến'), 
(379, '50-C1-00074', N'trực tuyến'),
(380, '50-C1-00075', N'đang bận'), 
(381, '50-C1-00076', N'trực tuyến'),
(382, '50-C1-00077', N'trực tuyến'), 
(383, '50-C1-00078', N'đang bận'),
(384, '50-C1-00079', N'trực tuyến'), 
(385, '50-C1-00080', N'trực tuyến'),
(386, '50-C1-00081', N'đang bận'), 
(387, '50-C1-00082', N'trực tuyến'),
(388, '50-C1-00083', N'trực tuyến'), 
(389, '50-C1-00084', N'đang bận'),
(390, '50-C1-00085', N'trực tuyến'), 
(391, '50-C1-00086', N'trực tuyến'),
(392, '50-C1-00087', N'đang bận'), 
(393, '50-C1-00088', N'trực tuyến'),
(394, '50-C1-00089', N'trực tuyến'), 
(395, '50-C1-00090', N'đang bận');
INSERT INTO ADMIN (user_ID, quyen_han) VALUES
(1, N'Quản trị hệ thống'),
(2, N'Quản lý người dùng'),
(3, N'Quản lý nhà hàng'),
(4, N'Quản lý khuyến mãi'),
(5, N'Hỗ trợ khách hàng'),
(6, N'Quản lý báo cáo'),
(7, N'Quản lý kỹ thuật'),    
(8, N'Quản lý tài chính');        
INSERT INTO FOOD (food_ID, gia, ten, mo_ta, trang_thai, anh, diem_danh_gia) VALUES
(1000, 30000, N'Bánh mì thịt', N'Bánh mì Việt Nam', N'còn hàng', 'https://cdn.tgdd.vn/2021/05/CookRecipe/Avatar/banh-mi-thit-bo-nuong-thumbnail-1.jpg', 4.8),
(1001, 45000, N'Phở bò', N'Phở truyền thống', N'còn hàng', 'https://cdn.tgdd.vn/Files/2022/01/25/1412805/cach-nau-pho-bo-nam-dinh-chuan-vi-thom-ngon-nhu-hang-quan-202201250230038502.jpg', 4.9),
(1002, 25000, N'Trà đá', N'Nước giải khát', N'còn hàng', 'https://bephue.com/wp-content/uploads/2022/11/Tra.png', 4.0),
(1003, 50000, N'Cơm gà xối mỡ', N'Cơm nóng, gà giòn', N'còn hàng', 'https://cdn.tgdd.vn/2021/01/CookRecipe/GalleryStep/thanh-pham-362.jpg', 4.4),
(1004, 20000, N'Nước cam', N'Cam tươi nguyên chất', N'hết hàng', 'https://cdn.tgdd.vn/Files/2018/11/27/1134029/cong-dung-cua-nuoc-cam-tuoi-va-cach-bao-quan-nuoc-cam-tot-nhat-6.jpg', 4.2),
(1005, 35000, N'Bún chả', N'Bún chả Hà Nội', N'còn hàng', 'https://cdn.zsoft.solutions/poseidon-web/app/media/Kham-pha-am-thuc/07.2024/090724-bun-cha-ha-noi-buffet-poseidon-thumb.jpg', 4.5),
(1006, 60000, N'Pizza hải sản', N'Pizza cỡ nhỏ', N'còn hàng', 'https://cdn.tgdd.vn/2020/09/CookProduct/1200bzhspm-1200x676.jpg', 3.9),
(1007, 15000, N'Trà sữa trân châu', N'Trà sữa truyền thống', N'còn hàng', 'https://dayphache.edu.vn/wp-content/uploads/2020/02/mon-tra-sua-tran-chau.jpg', 4.1),
(1008, 40000, N'Gà rán', N'Gà giòn cay', N'còn hàng', 'https://cokhiviendong.com/wp-content/uploads/2019/01/kinnh-nghi%E1%BB%87m-m%E1%BB%9F-qu%C3%A1n-g%C3%A0-r%C3%A1n-7.jpg', 4.6),
(1009, 25000, N'Bánh flan', N'Món tráng miệng', N'còn hàng', 'https://monngonmoingay.com/wp-content/uploads/2024/08/cach-lam-banh-flan-bang-noi-chien-khong-dau-1-1.jpg', 4.7),
(1010, 55000, N'Bún bò Huế đặc biệt', N'Bún bò Huế chuẩn vị, nhiều thịt', N'còn hàng', 'https://static.vinwonders.com/production/bun-bo-hue-1.jpg', 4.8),
(1011, 65000, N'Lẩu thái mini', N'Lẩu thái chua cay cho 1 người', N'còn hàng', 'https://foodparadise.vn/uploads/Product/CNL/Lau/lau_thai_hs_1_ng.jpg', 4.5),
(1012, 12000, N'Nước lọc đóng chai', N'Nước tinh khiết', N'còn hàng', 'https://drinkocany.com/wp-content/uploads/2022/05/nuoc-uong-dong-chai.jpg', 4.1),
(1013, 32000, N'Bánh mì gà xé', N'Bánh mì giòn, gà xé thơm ngon', N'còn hàng', 'https://cdn.tgdd.vn/2021/01/CookRecipe/Avatar/banh-mi-ga-truyen-thong-thumbnail.jpg', 4.3),
(1014, 28000, N'Cà phê đen đá', N'Cà phê nguyên chất, pha phin', N'còn hàng', 'https://congthucphache.com/wp-content/uploads/2023/07/358023700_571477475155214_229810017346216164_n.jpg', 4.7),
(1015, 75000, N'Sushi cuộn cá hồi', N'Set sushi 8 miếng cá hồi tươi', N'còn hàng', 'https://hatoyama.vn/wp-content/uploads/2020/05/sushi-com-cuon-ca-hoi-ca-ngu-bo-12-8-1200.jpg', 4.9),
(1016, 50000, N'Bánh pizza chay', N'Pizza rau củ cho người ăn chay', N'hết hàng', 'https://img.dominos.vn/cach-lam-pizza-chay-0.jpg', 4.0),
(1017, 18000, N'Sinh tố bơ', N'Bơ tươi, sữa đặc', N'còn hàng', 'https://cdn.tgdd.vn/2021/08/CookRecipe/GalleryStep/thanh-pham-1351.jpg', 4.4),
(1018, 38000, N'Kem ốc quế', N'Kem vanilla ốc quế lớn', N'còn hàng', 'https://file.hstatic.net/200000648353/file/vo_oc_que_de_bang_786f29722efb42aba871aa79746e1bf1.jpg', 4.6),
(1019, 42000, N'Gà viên chiên xù', N'Gà viên tẩm bột giòn', N'còn hàng', 'https://cdn.tgdd.vn/Files/2021/09/26/1385620/cach-lam-uc-ga-chien-thom-ngon-hap-dan-gion-tan-an-la-ghien-202109260056175464.jpg', 4.2),
(1020, 58000, N'Mì Ý hải sản', N'Mì Ý sốt cà chua, tôm mực', N'còn hàng', 'https://daynauan.info.vn/wp-content/uploads/2018/03/mi-y-hai-san.jpg', 4.5),
(1021, 22000, N'Bánh tiêu', N'Bánh tiêu chiên nóng', N'còn hàng', 'https://daylambanh.edu.vn/wp-content/uploads/2020/01/cach-lam-banh-tieu-600x400.jpg', 3.8),
(1022, 19000, N'Trà đào cam sả', N'Trà trái cây mát lạnh', N'còn hàng', 'https://eggyolk.vn/wp-content/uploads/2024/07/tra-dao-cam-sa.jpg', 4.3),
(1023, 70000, N'Set gà rán 2 người', N'2 miếng gà, khoai tây, nước', N'còn hàng', 'https://media.loveitopcdn.com/38362/thumb/z6324883396939-1ff5756a8a6bddb3b8e6c0ce8933c144.jpg', 4.7),
(1024, 26000, N'Xôi xéo', N'Xôi đậu xanh, hành phi, ruốc', N'còn hàng', 'https://cdn.tgdd.vn/2022/01/CookRecipe/Avatar/xoi-xeo-gao-nep-nau-bang-noi-com-dien-thumbnail.jpg', 4.1),
(1025, 48000, N'Bún riêu cua', N'Bún riêu cua đồng, chả', N'còn hàng', 'https://cdn.tgdd.vn/2020/11/CookRecipe/Avatar/bun-rieu-cua-dong-thumbnail-1.jpg', 4.6),
(1026, 85000, N'Combo Burger bò', N'Burger bò lớn, khoai tây chiên', N'còn hàng', 'https://burgerking.vn/media/catalog/product/cache/1/image/1800x/040ec09b1e35df139433887a97daa66f/c/o/combo-burger-baconking_-1-mieng-bo.jpg', 4.9),
(1027, 23000, N'Sữa chua nếp cẩm', N'Sữa chua lên men, nếp cẩm', N'còn hàng', 'https://beptruong.edu.vn/wp-content/uploads/2019/03/sua-chua-nep-cam.jpg', 4.0),
(1028, 33000, N'Bánh bao nhân thịt', N'Bánh bao hấp nóng', N'còn hàng', 'https://ruoctom.com/wp-content/uploads/2020/10/banh-bao-nhan-thap-cam-banh-bao-nhan-thap-cam-17-1529372830-543-width650height488.jpg', 4.2),
(1029, 62000, N'Cơm sườn bì chả', N'Cơm tấm sườn, bì, chả', N'còn hàng', 'https://i-giadinh.vnecdn.net/2024/03/07/7Honthinthnhphm1-1709800144-8583-1709800424.jpg', 4.5),
(1030, 20000, N'Khoai tây chiên', N'Khoai tây cắt lát chiên giòn', N'còn hàng', 'https://i-giadinh.vnecdn.net/2025/04/27/Khoaitaychien6vnexpress-174574-6122-2456-1745744819.jpg', 4.1),
(1031, 36000, N'Chè thập cẩm', N'Chè nhiều loại hạt', N'còn hàng', 'https://cdn11.dienmaycholon.vn/filewebdmclnew/public/userupload/files/kien-thuc/cach-nau-che-thap-cam-3-mien/cach-nau-che-thap-cam-3-mien-14.jpg', 4.3),
(1032, 95000, N'Bánh kem nhỏ', N'Bánh kem size 10cm', N'còn hàng', 'https://file.hstatic.net/1000398438/article/img_6356_fda1c5eaa44a4c2faa616b56489fd3ad_1024x1024.jpg', 4.8),
(1033, 49000, N'Món gỏi cuốn tôm thịt', N'Gỏi cuốn tươi mát', N'hết hàng', 'https://cdn.tgdd.vn/2021/08/CookRecipe/Avatar/goi-cuon-tom-thit-thumbnail-1.jpg', 4.4),
(1034, 15000, N'Sữa đậu nành', N'Sữa đậu nành tươi', N'còn hàng', 'https://file.hstatic.net/200000700229/article/1114510-15583224785381977809742-1_bf76d1d336f64efd8b2193a7678b41e9.jpg', 4.0),
(1035, 80000, N'Thịt nướng xiên', N'Thịt heo nướng xiên kiểu Hàn', N'còn hàng', 'https://file.hstatic.net/200000700229/article/thit-xien-nuong_6a7113b291e94d46857cfa384a641f80.jpg', 4.7),
(1036, 55000, N'Phở gà', N'Phở gà ta, nước dùng ngọt', N'còn hàng', 'https://cdn.tgdd.vn/2021/09/CookProduct/1200(3)-1200x676-2.jpg', 4.5),
(1037, 29000, N'Trứng chiên', N'Trứng chiên hành', N'còn hàng', 'https://cdn.tgdd.vn/2021/01/CookProduct/Tong-hop-15-cach-lam-trung-chien-ngon-don-gian-hap-dan-de-lam-cho-bua-com-1-1200x676.jpg', 3.9),
(1038, 38000, N'Nước dừa tươi', N'Dừa xiêm Bến Tre', N'còn hàng', 'https://sieuthiandam.com/wp-content/uploads/2019/08/t7.jpg', 4.6),
(1039, 44000, N'Bánh crepe sầu riêng', N'Bánh crepe nhân sầu riêng', N'còn hàng', 'https://thermomixvietnam.vn/wp-content/uploads/2021/08/banh-crepe-sau-rieng-vang.jpg', 4.8),
(1040, 110000, N'Lẩu mắm', N'Lẩu mắm miền Tây', N'còn hàng', 'https://cdn.zsoft.solutions/poseidon-web/app/media/uploaded-files/110724-lau-mam-mien-tay-cung-buffet-poseidon-1-1.jpg', 4.3),
(1041, 19000, N'Sinh tố mãng cầu', N'Mãng cầu tươi, sữa chua', N'hết hàng', 'https://dayphache.edu.vn/wp-content/uploads/2016/06/sinh-to-mang-cau.jpg', 4.1),
(1042, 68000, N'Hambuger Double Cheese', N'Burger bò hai lớp phô mai', N'còn hàng', 'https://burgerking.vn/media/catalog/product/cache/1/image/1800x/040ec09b1e35df139433887a97daa66f/c/o/combo-double-cheese-burger.jpg', 4.9),
(1043, 31000, N'Bánh chuối', N'Bánh chuối nướng', N'còn hàng', 'https://giadungducsaigon.vn/wp-content/uploads/2022/04/banh-chuoi-chien-800x622.jpg', 4.2),
(1044, 45000, N'Gà bó xôi', N'Gà nguyên con bó xôi chiên', N'còn hàng', 'https://cdn.tgdd.vn/Files/2021/07/30/1371913/huong-dan-cach-lam-ga-bo-xoi-chien-phong-gion-ngon-202201070933283113.jpg', 4.7),
(1045, 14000, N'Bia Sài Gòn', N'Bia chai Sài Gòn Lager', N'còn hàng', 'https://cdn.tgdd.vn/Products/Images/2282/158349/bhx/thung-24-lon-bia-sai-gon-lager-330ml-202110111038144356.jpg', 3.5),
(1046, 52000, N'Cơm chiên hải sản', N'Cơm chiên tôm, mực', N'còn hàng', 'https://cdn.tgdd.vn/2021/01/CookProduct/comchienhaisan-1200x676.jpg', 4.6),
(1047, 99000, N'Bò lúc lắc', N'Thịt bò lúc lắc rau củ', N'còn hàng', 'https://i.ytimg.com/vi/0X5m98q3Pn0/maxresdefault.jpg', 4.8),
(1048, 27000, N'Rau câu dừa', N'Rau câu làm từ nước dừa', N'còn hàng', 'https://lypham.vn/wp-content/uploads/2024/09/meo-lam-rau-cau-dua-soi.jpg', 4.1),
(1049, 39000, N'Bánh khoai mì', N'Bánh khoai mì nướng', N'còn hàng', 'https://file.hstatic.net/200000721249/file/han-thom-ngon-beo-ngay-de-lam-tai-nha_51ffdfde5d284f579efa09e5989eadcd.jpg', 4.3);
INSERT INTO FOOD_BELONG VALUES
(1000, 201), (1001, 201), (1002, 201),
(1003, 202), (1004, 202),
(1005, 203),
(1006, 204), (1007, 204),
(1008, 205), (1009, 205),
(1010, 206), (1025, 206), (1036, 206),
(1005, 207), (1000, 207), (1041, 207),
(1010, 208), (1022, 208), (1046, 208),
(1009, 213), (1024, 213), (1048, 221),
(1001, 232), (1036, 232), (1025, 240),
(1040, 241), (1047, 237), (1003, 244), 
(1008, 210), (1019, 210), (1023, 210),
(1006, 211), (1020, 211), (1042, 211),
(1020, 215), (1030, 215), (1006, 222),
(1007, 219), (1014, 219), (1017, 219),
(1009, 231), (1018, 231), (1032, 231), 
(1027, 249), (1031, 249), (1048, 255),
(1012, 225), (1026, 225), (1033, 225),
(1045, 236), (1044, 236), (1043, 236),
(1039, 250), (1034, 250), (1033, 250), 
(1012, 226), (1012, 227), (1012, 228), (1012, 229), (1012, 230), (1012, 233), (1012, 234), 
(1012, 235), (1012, 237), (1012, 238), (1012, 239), (1012, 242), (1012, 243), (1012, 245), 
(1012, 246), (1012, 247), (1012, 248), (1012, 251), (1012, 252), (1012, 253), (1012, 254),
(1021, 226), (1021, 227), (1021, 228), (1021, 229), (1021, 230), (1021, 233), (1021, 234), 
(1021, 235), (1021, 237), (1021, 238), (1021, 239), (1021, 242), (1021, 243), (1021, 245), 
(1021, 246), (1021, 247), (1021, 248), (1021, 251), (1021, 252), (1021, 253), (1021, 254);
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang, ngay_tao)
VALUES
(500, 201, 101, N'đang xử lý', N'Không cay', N'Hà Nội', 75000, 15000, DATEADD(hour, -2, GETDATE())),
(501, 201, 102, N'hoàn tất', N'Ít nước', N'TP.HCM', 60000, 10000, DATEADD(day, -5, GETDATE())),
(502, 203, 103, N'hoàn tất', N'Thêm hành', N'Đà Nẵng', 80000, 12000, DATEADD(day, -10, GETDATE())),
(503, 203, 104, N'hoàn tất', N'Giao nhanh', N'Cần Thơ', 90000, 15000, DATEADD(hour, -4, GETDATE())),
(504, 204, 105, N'đang xử lý', NULL, N'Huế', 70000, 10000, DATEADD(minute, -30, GETDATE())),
(505, 205, 106, N'hủy', N'Khách hủy', N'Hà Nội', 45000, 10000, DATEADD(day, -1, GETDATE())),
(506, 206, 107, N'hoàn tất', N'Không gọi điện', N'Quận Ba Đình, Hà Nội', 120000, 15000, GETDATE()),
(507, 207, 108, N'hoàn tất', NULL, N'TP Thủ Đức, TP.HCM', 85000, 10000, DATEADD(day, -7, GETDATE())),
(508, 208, 109, N'đang xử lý', N'Cần gấp', N'Đà Nẵng', 150000, 20000, DATEADD(minute, -15, GETDATE())),
(509, 210, 110, N'đang xử lý', NULL, N'Cần Thơ', 65000, 12000, GETDATE()),
(510, 211, 111, N'hoàn tất', NULL, N'Hà Nội', 210000, 15000, DATEADD(week, -1, GETDATE())),
(511, 212, 112, N'hủy', N'Sai địa chỉ', N'TP.HCM', 55000, 0, DATEADD(day, -3, GETDATE())),
(512, 213, 113, N'đang giao', NULL, N'Đà Nẵng', 95000, 15000, DATEADD(hour, -1, GETDATE())),
(513, 214, 114, N'hoàn tất', N'Đóng hộp kem cẩn thận', N'Cần Thơ', 40000, 10000, DATEADD(day, -2, GETDATE())),
(514, 215, 115, N'đang xử lý', N'Sợi mì dai', N'Hà Nội', 75000, 15000, DATEADD(hour, -6, GETDATE())),
(515, 216, 116, N'hoàn tất', NULL, N'TP.HCM', 180000, 15000, DATEADD(hour, -7, GETDATE())),
(516, 217, 117, N'đang xử lý', NULL, N'Đà Nẵng', 220000, 20000, DATEADD(minute, -45, GETDATE())),
(517, 218, 118, N'hủy', N'Giao quá lâu', N'Hà Nội', 55000, 0, DATEADD(day, -4, GETDATE())),
(518, 219, 119, N'đang giao', N'Mang lên lầu 5', N'TP.HCM', 35000, 10000, GETDATE()),
(519, 220, 120, N'đang xử lý', NULL, N'Đà Nẵng', 70000, 12000, DATEADD(minute, -5, GETDATE())),
(520, 221, 121, N'hoàn tất', N'Món ăn nóng', N'Hà Nội', 105000, 15000, DATEADD(day, -1, GETDATE())),
(521, 222, 122, N'đang xử lý', N'Cần nhiều tương', N'TP.HCM', 130000, 10000, DATEADD(hour, -3, GETDATE())),
(522, 223, 123, N'hoàn tất', NULL, N'Đà Nẵng', 90000, 15000, DATEADD(week, -2, GETDATE())),
(523, 224, 124, N'hoàn tất', N'Gọi điện trước 5p', N'Hà Nội', 60000, 10000, GETDATE()),
(524, 225, 125, N'đang xử lý', NULL, N'TP.HCM', 115000, 12000, DATEADD(minute, -10, GETDATE()));
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang, ngay_tao)
VALUES
(535, 226, 126, N'hoàn tất', N'Đóng gói món chè cẩn thận', N'Đà Nẵng', 65000, 10000, DATEADD(hour, -8, GETDATE())),
(538, 201, 101, N'hoàn tất', N'Giao hàng nhanh.', N'Hà Nội', 90000, 15000, DATEADD(day, -1, GETDATE())),
(539, 202, 102, N'hoàn tất', N'Giao giờ trưa.', N'TP.HCM', 75000, 10000, DATEADD(hour, -3, GETDATE())),
(540, 203, 103, N'hoàn tất', NULL, N'Đà Nẵng', 110000, 20000, GETDATE()),
(541, 204, 104, N'hoàn tất', NULL, N'Cần Thơ', 40000, 0, DATEADD(day, -7, GETDATE())),
(542, 205, 105, N'hoàn tất', N'Thêm đá.', N'Huế', 55000, 10000, DATEADD(hour, -5, GETDATE())),
(543, 206, 106, N'hoàn tất', N'Giao qua cổng bảo vệ.', N'Quận 7, TP.HCM', 80000, 15000, GETDATE()),
(544, 207, 107, N'hoàn tất', N'Cần nhiều tương.', N'Quận Ba Đình, Hà Nội', 70000, 10000, GETDATE()),
(545, 208, 108, N'hoàn tất', NULL, N'TP Thủ Đức, TP.HCM', 130000, 0, DATEADD(day, -2, GETDATE())),
(546, 209, 109, N'hoàn tất', N'Món chè ngon.', N'Đà Nẵng', 30000, 12000, DATEADD(hour, -6, GETDATE())),
(547, 210, 110, N'hoàn tất', N'Khách ở tầng 8.', N'Cần Thơ', 180000, 20000, GETDATE()),
(548, 211, 111, N'hoàn tất', N'Cần gấp.', N'Quận Hoàn Kiếm, Hà Nội', 250000, 15000, GETDATE()),
(549, 212, 112, N'hoàn tất', NULL, N'Quận 3, TP.HCM', 77000, 0, DATEADD(day, -4, GETDATE())),
(550, 213, 113, N'hoàn tất', N'Giao hàng rất nhanh.', N'Đà Nẵng', 60000, 12000, DATEADD(hour, -2, GETDATE())),
(551, 214, 114, N'hoàn tất', NULL, N'Cần Thơ', 30000, 10000, GETDATE()),
(552, 215, 115, N'hoàn tất', N'Sợi mì dai.', N'Quận Tây Hồ, Hà Nội', 75000, 15000, GETDATE()),
(553, 216, 116, N'hoàn tất', N'Quán hết món.', N'Quận Phú Nhuận, TP.HCM', 190000, 0, DATEADD(day, -1, GETDATE())),
(554, 217, 117, N'hoàn tất', N'Hải sản tươi ngon.', N'Đà Nẵng', 160000, 20000, DATEADD(hour, -8, GETDATE())),
(555, 218, 118, N'hoàn tất', N'Giao cẩn thận.', N'Quận Đống Đa, Hà Nội', 55000, 10000, GETDATE()),
(556, 219, 119, N'hoàn tất', NULL, N'Quận Tân Bình, TP.HCM', 35000, 10000, GETDATE()),
(558, 221, 121, N'hoàn tất', N'Bánh bột lọc ngon.', N'Quận Long Biên, Hà Nội', 40000, 12000, DATEADD(hour, -4, GETDATE())),
(559, 222, 122, N'hoàn tất', N'Giao giờ tối.', N'Quận Bình Thạnh, TP.HCM', 130000, 15000, GETDATE()),
(560, 223, 123, N'hoàn tất', N'Cần nhiều sốt.', N'Đà Nẵng', 90000, 10000, GETDATE()),
(561, 224, 124, N'hoàn tất', NULL, N'Quận Nam Từ Liêm, Hà Nội', 50000, 0, DATEADD(day, -2, GETDATE())),
(562, 225, 125, N'hoàn tất', N'Dimsum nóng.', N'Quận Gò Vấp, TP.HCM', 115000, 12000, DATEADD(hour, -6, GETDATE())),
(593, 201, 156, N'hoàn tất', N'Đơn lớn.', N'Quận 7, TP.HCM', 180000, 20000, GETDATE()),
(594, 202, 157, N'hoàn tất', N'Sườn bì chả.', N'Hà Nội', 80000, 10000, GETDATE()),
(595, 203, 158, N'hoàn tất', N'Phở nóng.', N'TP Thủ Đức, TP.HCM', 90000, 15000, DATEADD(day, -14, GETDATE())),
(596, 204, 159, N'hoàn tất', N'Quán chưa mở.', N'Đà Nẵng', 100000, 0, DATEADD(hour, -15, GETDATE())),
(597, 205, 160, N'hoàn tất', N'Trà sữa.', N'Cần Thơ', 30000, 5000, GETDATE()),
(598, 206, 161, N'hoàn tất', NULL, N'Hà Nội', 85000, 10000, GETDATE()),
(599, 207, 162, N'hoàn tất', N'Bún đậu ngon.', N'TP.HCM', 65000, 12000, DATEADD(day, -16, GETDATE())),
(600, 208, 163, N'hoàn tất', N'Món Huế.', N'Đà Nẵng', 70000, 15000, GETDATE()),
(601, 209, 164, N'hoàn tất', N'Chè.', N'Cần Thơ', 40000, 10000, GETDATE()),
(602, 210, 165, N'hoàn tất', N'Đắt.', N'Hà Nội', 90000, 0, DATEADD(hour, -17, GETDATE())),
(603, 211, 166, N'hoàn tất', N'Pizza ngon.', N'TP.HCM', 180000, 15000, DATEADD(day, -18, GETDATE())),
(604, 212, 167, N'hoàn tất', N'Cơm niêu.', N'Đà Nẵng', 60000, 10000, GETDATE()),
(605, 213, 168, N'hoàn tất', N'Bánh xèo.', N'Hà Nội', 75000, 15000, GETDATE()),
(606, 214, 169, N'hoàn tất', N'Kem.', N'TP.HCM', 35000, 10000, DATEADD(hour, -19, GETDATE())),
(608, 216, 171, N'hoàn tất', N'Lẩu.', N'Hà Nội', 200000, 20000, GETDATE()),
(609, 217, 172, N'hoàn tất', N'Hải sản.', N'TP.HCM', 180000, 15000, GETDATE()),
(610, 218, 173, N'hoàn tất', N'Cháo lòng.', N'Đà Nẵng', 55000, 10000, DATEADD(hour, -21, GETDATE())),
(612, 220, 175, N'hoàn tất', N'Trà sữa.', N'TP.HCM', 35000, 10000, GETDATE()),
(613, 221, 176, N'hoàn tất', N'Bánh bột lọc.', N'Đà Nẵng', 40000, 12000, GETDATE()),
(614, 222, 177, N'hoàn tất', N'Sushi.', N'Hà Nội', 130000, 15000, DATEADD(hour, -23, GETDATE())),
(615, 223, 178, N'hoàn tất', N'Mì ý.', N'TP.HCM', 60000, 10000, GETDATE()),
(616, 224, 179, N'hoàn tất', N'Bánh canh.', N'Đà Nẵng', 80000, 15000, GETDATE()),
(617, 225, 180, N'hủy', N'Khách gọi nhầm.', N'Hà Nội', 115000, 0, DATEADD(day, -24, GETDATE())),
(648, 201, 121, N'hoàn tất', N'Phở.', N'Hà Nội', 105000, 15000, GETDATE()),
(649, 202, 122, N'hoàn tất', N'Cơm Tấm.', N'TP.HCM', 55000, 0, DATEADD(day, -35, GETDATE())),
(650, 203, 123, N'hoàn tất', N'Phở.', N'Đà Nẵng', 70000, 10000, DATEADD(hour, -6, GETDATE())),
(651, 204, 124, N'hoàn tất', N'Lẩu Bò.', N'Cần Thơ', 90000, 15000, GETDATE()),
(652, 205, 125, N'hoàn tất', N'Phúc Long.', N'Huế', 35000, 5000, GETDATE()),
(653, 206, 126, N'hoàn tất', N'Bún Chả.', N'Đà Nẵng', 85000, 10000, DATEADD(hour, -7, GETDATE())),
(654, 207, 127, N'hoàn tất', N'Bún Đậu.', N'Hà Nội', 60000, 15000, GETDATE()),
(655, 208, 128, N'hoàn tất', N'Món Huế.', N'TP.HCM', 100000, 10000, GETDATE()),
(656, 209, 129, N'hủy', N'Chè Thái.', N'Đà Nẵng', 45000, 0, DATEADD(day, -36, GETDATE())),
(657, 210, 130, N'hoàn tất', N'Gà Rán.', N'Hà Nội', 75000, 10000, DATEADD(hour, -8, GETDATE())),
(658, 211, 131, N'đang giao', N'Pizza.', N'TP.HCM', 200000, 15000, GETDATE()),
(659, 212, 132, N'đang xử lý', N'Cơm Niêu.', N'Đà Nẵng', 65000, 12000, GETDATE()),
(660, 213, 133, N'hủy', N'Bánh Xèo.', N'Hà Nội', 55000, 0, DATEADD(day, -37, GETDATE())),
(661, 214, 134, N'hoàn tất', N'Kem.', N'TP.HCM', 30000, 10000, DATEADD(hour, -9, GETDATE())),
(662, 215, 135, N'đang giao', N'Mì Cay.', N'Đà Nẵng', 75000, 15000, GETDATE()),
(663, 216, 136, N'đang xử lý', N'Buffet Lẩu.', N'Hà Nội', 180000, 15000, GETDATE()),
(664, 217, 137, N'hủy', N'Hải Sản.', N'TP.HCM', 150000, 0, DATEADD(day, -38, GETDATE())),
(665, 218, 138, N'hoàn tất', N'Cháo Lòng.', N'Đà Nẵng', 55000, 10000, DATEADD(hour, -10, GETDATE())),
(666, 219, 139, N'đang giao', N'Cafe.', N'Hà Nội', 35000, 10000, GETDATE()),
(667, 220, 140, N'đang xử lý', N'Trà Sữa.', N'TP.HCM', 50000, 10000, GETDATE()),
(668, 221, 141, N'hủy', N'Bánh Bột Lọc.', N'Đà Nẵng', 40000, 0, DATEADD(day, -39, GETDATE())),
(669, 222, 142, N'hoàn tất', N'Sushi.', N'Hà Nội', 130000, 15000, DATEADD(hour, -11, GETDATE())),
(670, 223, 143, N'đang giao', N'Mì Ý.', N'TP.HCM', 80000, 10000, GETDATE()),
(671, 224, 144, N'đang xử lý', N'Bánh Canh.', N'Đà Nẵng', 60000, 15000, GETDATE()),
(672, 225, 145, N'hủy', N'Dimsum.', N'Hà Nội', 115000, 0, DATEADD(day, -40, GETDATE())),
(703, 201, 176, N'đang xử lý', N'Phở.', N'Đà Nẵng', 75000, 15000, GETDATE()),
(704, 202, 177, N'hủy', N'Cơm Tấm.', N'Hà Nội', 50000, 0, DATEADD(day, -48, GETDATE())),
(705, 203, 178, N'hoàn tất', N'Phở.', N'TP.HCM', 80000, 10000, DATEADD(hour, -20, GETDATE())),
(706, 204, 179, N'đang giao', N'Pizza.', N'Đà Nẵng', 90000, 15000, GETDATE()),
(707, 205, 180, N'đang xử lý', N'Trà sữa.', N'Huế', 30000, 5000, GETDATE()),
(708, 206, 181, N'hủy', N'Bún Chả.', N'TP.HCM', 120000, 0, DATEADD(day, -49, GETDATE())),
(709, 207, 182, N'hoàn tất', N'Bún Đậu.', N'Đà Nẵng', 65000, 12000, DATEADD(hour, -21, GETDATE())),
(710, 208, 183, N'đang giao', N'Món Huế.', N'Hà Nội', 70000, 10000, GETDATE()),
(711, 209, 184, N'đang xử lý', N'Chè Thái.', N'TP.HCM', 40000, 10000, GETDATE()),
(712, 210, 185, N'hủy', N'Gà Rán.', N'Đà Nẵng', 90000, 0, DATEADD(day, -50, GETDATE())),
(713, 211, 186, N'hoàn tất', N'Pizza.', N'Hà Nội', 180000, 15000, DATEADD(hour, -22, GETDATE())),
(714, 212, 187, N'đang giao', N'Cơm Niêu.', N'TP.HCM', 60000, 10000, GETDATE()),
(715, 213, 188, N'đang xử lý', N'Bánh Xèo.', N'Đà Nẵng', 75000, 15000, GETDATE()),
(716, 214, 189, N'hoàn tất', N'Kem.', N'Hà Nội', 30000, 0, DATEADD(day, -51, GETDATE())),
(717, 215, 190, N'hoàn tất', N'Mì Cay.', N'TP.HCM', 55000, 10000, DATEADD(hour, -23, GETDATE()));
INSERT INTO ORDERS (order_ID, restaurant_ID, customer_ID, trang_thai, ghi_chu, dia_chi, gia_don_hang, phi_giao_hang, ngay_tao)
VALUES
(718, 216, 101, N'hoàn tất', N'Đã thanh toán qua VNPAY.', N'Hà Nội', 150000, 15000, DATEADD(hour, -1, GETDATE())),
(719, 217, 102, N'hoàn tất', N'Giao hàng rất nhanh.', N'TP.HCM', 110000, 10000, DATEADD(hour, -2, GETDATE())),
(720, 218, 103, N'hoàn tất', N'Cháo lòng ngon.', N'Đà Nẵng', 45000, 12000, DATEADD(hour, -3, GETDATE())),
(721, 219, 104, N'hoàn tất', N'Cafe thơm.', N'Cần Thơ', 30000, 5000, DATEADD(hour, -4, GETDATE())),
(722, 220, 105, N'hoàn tất', N'Trà sữa đóng gói kỹ.', N'Huế', 40000, 10000, DATEADD(hour, -5, GETDATE())),
(723, 221, 106, N'hoàn tất', N'Bánh bột lọc nóng.', N'Quận 7, TP.HCM', 55000, 15000, DATEADD(hour, -6, GETDATE())),
(724, 222, 107, N'hoàn tất', N'Sushi tươi.', N'Quận Ba Đình, Hà Nội', 140000, 10000, DATEADD(hour, -7, GETDATE())),
(725, 223, 108, N'hoàn tất', N'Mì Ý ngon.', N'TP Thủ Đức, TP.HCM', 75000, 12000, DATEADD(hour, -8, GETDATE())),
(726, 224, 109, N'hoàn tất', N'Bánh canh cua đầy đủ.', N'Đà Nẵng', 88000, 15000, DATEADD(hour, -9, GETDATE())),
(727, 225, 110, N'hoàn tất', N'Dimsum nóng.', N'Cần Thơ', 105000, 10000, DATEADD(hour, -10, GETDATE())),
(728, 226, 111, N'hoàn tất', N'Chè khúc bạch mát.', N'Quận Hoàn Kiếm, Hà Nội', 45000, 10000, DATEADD(hour, -11, GETDATE())),
(729, 227, 112, N'hoàn tất', N'Bún riêu ngon.', N'Quận 3, TP.HCM', 68000, 12000, DATEADD(hour, -12, GETDATE())),
(730, 228, 113, N'hoàn tất', N'Cơm gà giao nhanh.', N'Đà Nẵng', 77000, 15000, DATEADD(hour, -13, GETDATE())),
(731, 229, 114, N'hoàn tất', N'Thịt heo 2 da giòn.', N'Quận Cái Răng, Cần Thơ', 125000, 20000, DATEADD(hour, -14, GETDATE())),
(732, 230, 115, N'hoàn tất', N'Bánh ướt nóng.', N'Quận Tây Hồ, Hà Nội', 35000, 5000, DATEADD(hour, -15, GETDATE())),
(733, 231, 116, N'hoàn tất', N'Kem Swensens ngon.', N'Quận Phú Nhuận, TP.HCM', 90000, 10000, DATEADD(hour, -16, GETDATE())),
(734, 232, 117, N'hoàn tất', N'Phở cuốn chất lượng.', N'Quận Sơn Trà, Đà Nẵng', 65000, 15000, DATEADD(hour, -17, GETDATE())),
(735, 233, 118, N'hoàn tất', N'Bún bò Huế vị đậm.', N'Quận Đống Đa, Hà Nội', 135000, 10000, DATEADD(hour, -18, GETDATE())),
(736, 234, 119, N'hoàn tất', N'Súp cua nóng hổi.', N'Quận Tân Bình, TP.HCM', 40000, 12000, DATEADD(hour, -19, GETDATE())),
(737, 235, 120, N'hoàn tất', N'Hủ tiếu Nam Vang ngon.', N'Quận Liên Chiểu, Đà Nẵng', 80000, 15000, DATEADD(hour, -20, GETDATE())),
(738, 236, 121, N'hoàn tất', N'Trà Lipton đóng gói tốt.', N'Quận Long Biên, Hà Nội', 25000, 5000, DATEADD(hour, -21, GETDATE())),
(739, 237, 122, N'hoàn tất', N'Bò né chất lượng.', N'Quận Bình Thạnh, TP.HCM', 105000, 15000, DATEADD(hour, -22, GETDATE())),
(740, 238, 123, N'hoàn tất', N'Cà phê đậm đà.', N'Quận Cẩm Lệ, Đà Nẵng', 35000, 10000, DATEADD(hour, -23, GETDATE())),
(741, 239, 124, N'hoàn tất', N'Nước ép tươi.', N'Quận Nam Từ Liêm, Hà Nội', 45000, 10000, DATEADD(day, -2, GETDATE())),
(742, 240, 125, N'hoàn tất', N'Bún mọc ngon.', N'Quận Gò Vấp, TP.HCM', 60000, 12000, DATEADD(day, -3, GETDATE())),
(743, 241, 126, N'hoàn tất', N'Lẩu mắm đúng vị.', N'Quận Thanh Khê, Đà Nẵng', 180000, 20000, DATEADD(day, -4, GETDATE())),
(744, 242, 127, N'hoàn tất', N'Bánh tét gói kỹ.', N'Quận Hoàng Mai, Hà Nội', 30000, 5000, DATEADD(day, -5, GETDATE())),
(745, 243, 128, N'hoàn tất', N'Bánh chưng nóng.', N'Quận Tân Phú, TP.HCM', 55000, 10000, DATEADD(day, -6, GETDATE())),
(758, 201, 141, N'hoàn tất', N'Phở ngon.', N'Quận Liên Chiểu, Đà Nẵng', 90000, 15000, DATEADD(day, -19, GETDATE())),
(759, 202, 142, N'hoàn tất', N'Cơm tấm sườn.', N'Quận Hoàn Kiếm, Hà Nội', 70000, 10000, DATEADD(day, -20, GETDATE())),
(760, 203, 143, N'hoàn tất', N'Bún chả.', N'Quận 1, TP.HCM', 40000, 12000, DATEADD(day, -21, GETDATE())),
(761, 204, 144, N'hoàn tất', N'Pizza hải sản.', N'Quận Hải Châu, Đà Nẵng', 100000, 20000, DATEADD(day, -22, GETDATE())),
(762, 205, 145, N'hoàn tất', N'Trà sữa.', N'Quận Tây Hồ, Hà Nội', 25000, 5000, DATEADD(day, -23, GETDATE())),
(763, 206, 146, N'hoàn tất', N'Bún chả ngon.', N'Quận Bình Thạnh, TP.HCM', 75000, 15000, DATEADD(day, -24, GETDATE())),
(764, 207, 147, N'hoàn tất', N'Bún đậu mắm tôm.', N'Quận Cẩm Lệ, Đà Nẵng', 60000, 10000, DATEADD(day, -25, GETDATE())),
(765, 208, 148, N'hoàn tất', N'Món Huế.', N'Quận Long Biên, Hà Nội', 85000, 15000, DATEADD(day, -26, GETDATE())),
(766, 209, 149, N'hoàn tất', N'Chè Thái.', N'Quận 5, TP.HCM', 30000, 10000, DATEADD(day, -27, GETDATE())),
(767, 210, 150, N'hoàn tất', N'Gà Rán.', N'Quận Thanh Khê, Đà Nẵng', 50000, 10000, DATEADD(day, -28, GETDATE())),
(768, 211, 151, N'hoàn tất', N'Pizza.', N'Quận Hoàng Mai, Hà Nội', 180000, 15000, DATEADD(day, -29, GETDATE())),
(769, 212, 152, N'hoàn tất', N'Cơm Niêu.', N'Quận Tân Phú, TP.HCM', 60000, 10000, DATEADD(day, -30, GETDATE())),
(770, 213, 153, N'hoàn tất', N'Bánh Xèo.', N'Quận Sơn Trà, Đà Nẵng', 75000, 15000, DATEADD(day, -31, GETDATE())),
(771, 214, 154, N'hoàn tất', N'Kem.', N'Quận Hà Đông, Hà Nội', 30000, 10000, DATEADD(day, -32, GETDATE())),
(772, 215, 155, N'hoàn tất', N'Mì Cay.', N'Quận 12, TP.HCM', 55000, 10000, DATEADD(day, -33, GETDATE())),
(773, 216, 156, N'hoàn tất', N'Lẩu.', N'Quận 7, TP.HCM', 150000, 20000, DATEADD(day, -34, GETDATE())),
(774, 217, 157, N'hoàn tất', N'Hải Sản.', N'Quận Ba Đình, Hà Nội', 160000, 15000, DATEADD(day, -35, GETDATE())),
(775, 218, 158, N'hoàn tất', N'Cháo Lòng.', N'TP Thủ Đức, TP.HCM', 45000, 10000, DATEADD(day, -36, GETDATE())),
(776, 219, 159, N'hoàn tất', N'Cafe.', N'Quận Hải Châu, Đà Nẵng', 35000, 10000, DATEADD(day, -37, GETDATE())),
(777, 220, 160, N'hoàn tất', N'Trà Sữa.', N'Quận Ninh Kiều, Cần Thơ', 50000, 10000, DATEADD(day, -38, GETDATE())),
(778, 221, 161, N'hoàn tất', N'Bánh Bột Lọc.', N'Quận Hoàn Kiếm, Hà Nội', 40000, 12000, DATEADD(day, -39, GETDATE())),
(779, 222, 162, N'hoàn tất', N'Sushi.', N'Quận 3, TP.HCM', 120000, 15000, DATEADD(day, -40, GETDATE())),
(780, 223, 163, N'hoàn tất', N'Mì Ý.', N'Quận Ngũ Hành Sơn, Đà Nẵng', 70000, 10000, DATEADD(day, -41, GETDATE())),
(781, 224, 164, N'hoàn tất', N'Bánh Canh.', N'Quận Cái Răng, Cần Thơ', 55000, 10000, DATEADD(day, -42, GETDATE())),
(782, 225, 165, N'hoàn tất', N'Dimsum.', N'Quận Tây Hồ, Hà Nội', 105000, 12000, DATEADD(day, -43, GETDATE())),
(783, 226, 166, N'hoàn tất', N'Chè Khúc Bạch.', N'Quận Phú Nhuận, TP.HCM', 40000, 10000, DATEADD(day, -44, GETDATE())),
(784, 227, 167, N'hoàn tất', N'Bún Riêu.', N'Quận Sơn Trà, Đà Nẵng', 98000, 15000, DATEADD(day, -45, GETDATE())),
(785, 228, 168, N'hoàn tất', N'Cơm Gà.', N'Quận Đống Đa, Hà Nội', 90000, 15000, DATEADD(day, -46, GETDATE())),
(786, 229, 169, N'hoàn tất', N'Thịt Heo.', N'Quận Tân Bình, TP.HCM', 135000, 10000, DATEADD(day, -47, GETDATE())),
(787, 230, 170, N'hoàn tất', N'Bánh Ướt.', N'Quận Liên Chiểu, Đà Nẵng', 40000, 10000, DATEADD(day, -48, GETDATE())),
(788, 231, 171, N'hoàn tất', N'Kem.', N'Quận Long Biên, Hà Nội', 85000, 12000, DATEADD(day, -49, GETDATE())),
(789, 232, 172, N'hoàn tất', N'Phở Cuốn.', N'Quận Bình Tân, TP.HCM', 60000, 10000, DATEADD(day, -50, GETDATE())),
(790, 233, 173, N'hoàn tất', N'Bún Bò.', N'Quận Cẩm Lệ, Đà Nẵng', 95000, 15000, DATEADD(day, -51, GETDATE())),
(791, 234, 174, N'hoàn tất', N'Súp Cua.', N'Quận Nam Từ Liêm, Hà Nội', 55000, 10000, DATEADD(day, -52, GETDATE())),
(792, 235, 175, N'hoàn tất', N'Hủ Tiếu.', N'Quận Gò Vấp, TP.HCM', 110000, 12000, DATEADD(day, -53, GETDATE())),
(793, 236, 176, N'hoàn tất', N'Trà Lipton.', N'Quận Thanh Khê, Đà Nẵng', 30000, 5000, DATEADD(day, -54, GETDATE())),
(794, 237, 177, N'hoàn tất', N'Bò Né.', N'Quận Hoàng Mai, Hà Nội', 90000, 10000, DATEADD(day, -55, GETDATE())),
(795, 238, 178, N'hoàn tất', N'Cafe.', N'Quận Tân Phú, TP.HCM', 45000, 10000, DATEADD(day, -56, GETDATE())),
(796, 239, 179, N'hoàn tất', N'Nước Ép.', N'Quận Sơn Trà, Đà Nẵng', 40000, 10000, DATEADD(day, -57, GETDATE())),
(797, 240, 180, N'hoàn tất', N'Bún Mọc.', N'Quận Hà Đông, Hà Nội', 60000, 15000, DATEADD(day, -58, GETDATE())),
(798, 241, 181, N'hoàn tất', N'Lẩu Mắm.', N'Quận 12, TP.HCM', 150000, 20000, DATEADD(day, -59, GETDATE())),
(799, 242, 182, N'hoàn tất', N'Bánh Tét.', N'Quận Hải Châu, Đà Nẵng', 35000, 10000, DATEADD(day, -60, GETDATE())),
(800, 243, 183, N'hoàn tất', N'Bánh Chưng.', N'Quận Cầu Giấy, Hà Nội', 50000, 10000, DATEADD(day, -61, GETDATE()));
INSERT INTO FOOD_ORDERED VALUES
(1000, 500),
(1001, 501),
(1003, 502),
(1005, 503),
(1006, 504),
(1007, 505),
(1010, 506), (1011, 506),
(1003, 507),
(1006, 508), (1007, 508),
(1008, 509),
(1015, 510),
(1001, 511),
(1014, 512),
(1018, 513), (1019, 513),
(1020, 514),
(1011, 515), (1012, 515), (1007, 515),
(1025, 516), (1026, 516),
(1017, 518),
(1027, 519), (1028, 519), (1029, 519),
(1030, 520), (1031, 520),
(1008, 521), (1009, 521),
(1042, 522),
(1045, 523), (1046, 523),
(1047, 524);
INSERT INTO DELIVERING (shipper_ID, order_ID) VALUES
(301, 500),
(302, 503),
(303, 504),
(306, 506),
(307, 507),
(308, 510),
(309, 512),
(310, 513),
(311, 515),
(312, 516),
(313, 518),
(314, 520),
(315, 523);
INSERT INTO RATING (order_ID, rating_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES
(501, 1, 1001, N'Phở ngon, ship nhanh.', 5),
(502, 1, 1003, N'Cơm gà ngon, gói kỹ.', 4),
(507, 1, 1003, N'Món ăn đầy đủ, shipper thân thiện.', 5),
(510, 1, 1015, N'Pizza giao hơi nguội, nhưng hương vị tốt.', 3),
(513, 1, 1018, N'Kem ngon, shipper cẩn thận không bị tan chảy.', 5),
(515, 1, 1011, N'Lẩu thái vị đậm đà, rất vừa miệng.', 5),
(520, 1, 1030, N'Xôi dẻo, gà ngon, nên thử.', 4),
(522, 1, 1042, N'Burger chất lượng cao, đúng giá.', 5),
(502, 2, 1003, N'Giá hơi cao so với phần ăn.', 3),
(503, 1, 1005, N'Bún chả ổn, nhưng giao hàng hơi chậm.', 3),
(506, 1, 1010, N'Bún bò Huế truyền thống, rất ưng ý.', 5),
(523, 1, 1045, N'Bia lạnh, giao hàng nhanh chóng.', 4);
INSERT INTO PARENT_RESTAURANT (parent_id, child_id) VALUES
(201, 202),
(201, 203),
(204, 205),
(206, 207),
(206, 208),
(209, 210),
(211, 212),
(211, 213),
(215, 216),
(220, 221),
(220, 222),
(223, 224),
(230, 231);
INSERT INTO VOUCHER (voucher_ID, han_su_dung, mo_ta, dieu_kien_su_dung, gia_tri_su_dung, order_ID, customer_ID)
VALUES
(900, '2026-01-01', N'Giảm 30%', N'Đơn tối thiểu 50k', 30, 501, 102),
(901, '2026-06-01', N'Giảm 20%', N'Đơn tối thiểu 80k', 20, 502, 103),
(902, '2026-12-31', N'Freeship 100%', N'Đơn tối thiểu 0k', 100, NULL, 104),
(903, '2026-03-15', N'Giảm 10%', N'Đơn tối thiểu 100k', 10, NULL, 105),
(914, '2026-04-20', N'Giảm 50%', N'Đơn tối thiểu 150k', 50, 505, 106),
(915, '2027-01-01', N'Freeship 100%', N'Đơn tối thiểu 50k', 50, NULL, 107),
(906, '2026-08-10', N'Giảm 20%', N'Đơn tối thiểu 70k', 20, 507, 108),
(907, '2027-03-01', N'Giảm 15%', N'Đơn tối thiểu 120k', 15, NULL, 109),   
(908, '2026-02-05', N'Giảm 30%', N'Đơn tối thiểu 90k', 30, 510, 110),
(909, '2027-05-20', N'Giảm 5%', N'Đơn tối thiểu 0k', 5, 512, 111),
(910, '2026-07-25', N'Giảm 25%', N'Đơn tối thiểu 200k', 25, NULL, 112),   
(911, '2026-11-11', N'Freeship', N'Đơn tối thiểu 0k', 100, 515, 113),
(912, '2027-02-14', N'Giảm 15%', N'Đơn tối thiểu 30k', 15, NULL, 114),
(913, '2026-09-30', N'Giảm 25%', N'Đơn tối thiểu 150k', 25, 518, 115);


GO

-----------------------------------------------------------
-- REGION 4: TRIGGER NGHIỆP VỤ 
-----------------------------------------------------------

-- Trigger 1: Hoàn tiền Voucher khi đơn bị hủy --

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

-- Trigger 2: Cập nhật điểm raitng được food khi có sự thay đổi ở rating --

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
            3   -- Điểm mặc định nếu không còn rating
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
---- TEST TRIGGER 1
-----------------------------------
-- 
-- TC1 – Hủy đơn + voucher còn hạn → phải hoàn
DECLARE @vid INT, @oid INT;

SELECT TOP 1 @vid = voucher_ID, @oid = order_ID
FROM VOUCHER
WHERE han_su_dung >= GETDATE()   -- còn hạn
  AND order_ID IS NOT NULL;      -- đang được gán cho đơn

-- Reset trạng thái đơn để đảm bảo trigger kích hoạt
UPDATE ORDERS SET trang_thai = N'đang xử lý'
WHERE order_ID = @oid;

-- Thực hiện cập nhật sang 'hủy'
UPDATE ORDERS SET trang_thai = N'hủy'
WHERE order_ID = @oid;

-- Expected: VOUCHER.order_ID = NULL
SELECT voucher_ID, order_ID, han_su_dung
FROM VOUCHER
WHERE voucher_ID = @vid;

-- TC2 – Voucher hết hạn → Không hoàn
DECLARE @vid2 INT, @oid2 INT;

SELECT TOP 1 @vid2 = voucher_ID, @oid2 = order_ID
FROM VOUCHER
WHERE order_ID IS NOT NULL;

-- Giả lập voucher hết hạn
UPDATE VOUCHER SET han_su_dung = '2023-01-01'
WHERE voucher_ID = @vid2;

-- Reset trạng thái đơn
UPDATE ORDERS SET trang_thai = N'đang xử lý'
WHERE order_ID = @oid2;

-- Cập nhật sang 'hủy'
UPDATE ORDERS SET trang_thai = N'hủy'
WHERE order_ID = @oid2;

-- Expected: order_ID KHÔNG bị set NULL
SELECT voucher_ID, order_ID, han_su_dung
FROM VOUCHER
WHERE voucher_ID = @vid2;

-- TC3 - Đơn vốn đã 'hủy' → trigger không chạy lại
DECLARE @oid3 INT;

SELECT TOP 1 @oid3 = order_ID 
FROM ORDERS
WHERE trang_thai = N'hủy';

-- Update lại 'hủy'
UPDATE ORDERS SET trang_thai = N'hủy'
WHERE order_ID = @oid3;

-- Expected: Không thay đổi gì với voucher
SELECT v.*
FROM VOUCHER v
WHERE v.order_ID = @oid3;


-----------------------------------
---- TEST TRIGGER 2
-----------------------------------
-- 
-- TC4: Khi thêm rating mới → FOOD.Diem_danh_gia phải cập nhật theo AVG(rating).

DECLARE @food INT = (
    SELECT TOP 1 food_ID FROM FOOD ORDER BY food_ID
);

-- Insert rating mới
INSERT INTO RATING (order_ID, rating_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES (9000, 1, @food, N'Test Rating', 5);

-- Expected: Điểm trung bình tăng hoặc = 5 nếu là rating đầu tiên
SELECT food_ID, ten, Diem_danh_gia
FROM FOOD
WHERE food_ID = @food;


-- TC5: Update điểm rating → trigger phải tính lại AVG.

UPDATE RATING
SET Diem_danh_gia = 2
WHERE order_ID = 9000 AND rating_ID = 1;

-- Expected: FOOD.Diem_danh_gia cập nhật lại theo AVG
SELECT food_ID, ten, Diem_danh_gia
FROM FOOD
WHERE food_ID = @food;

-- TC6: Xóa rating của food → trigger cập nhật điểm mới.

DELETE FROM RATING
WHERE order_ID = 9000 AND rating_ID = 1;

-- Expected: Nếu không còn rating nào → Diem_danh_gia = 5
SELECT food_ID, ten, Diem_danh_gia
FROM FOOD
WHERE food_ID = @food;


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
