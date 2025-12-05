## TỔNG QUAN

File này dùng để **test 2 trigger**:

- **Trigger 1**: Hoàn voucher khi đơn bị hủy  
  - Điều kiện: trạng thái đơn đổi từ khác `N'hủy'` → `N'hủy'`, voucher đang gắn với đơn và **còn hạn** (`han_su_dung >= GETDATE()`).
  - Kết quả mong đợi: `UPDATE VOUCHER SET order_ID = NULL` cho đúng voucher đó.

- **Trigger 2**: Cập nhật điểm trung bình món ăn (`FOOD.Diem_danh_gia`) khi có thay đổi bảng `RATING`.  
  - Tính `AVG(Diem_danh_gia)` theo `food_ID`.  
  - Nếu không còn rating nào → set `Diem_danh_gia = 5` (default).

Khi test, **mỗi bạn nên chạy `ROLLBACK` sau từng testcase**, hoặc làm trên **DB riêng** để tránh ảnh hưởng kết quả của người khác.

---

## PHẦN A – TRIGGER HOÀN VOUCHER KHI ĐƠN HỦY

### A.0. Chuẩn bị dữ liệu mẫu (chạy 1 lần trước khi test)

Giả sử có các bảng & cột:

- `ORDERS(order_ID, customer_ID, trang_thai, ...)`
- `VOUCHER(voucher_ID, order_ID, han_su_dung, ...)`

Tạo dữ liệu dùng chung cho tất cả testcase:

```sql
-- Đơn 102 đang ở trạng thái 'đang giao' và đã gán voucher 300
UPDATE ORDERS
SET trang_thai = N'đang giao'
WHERE order_ID = 102;

UPDATE VOUCHER
SET order_ID = 102,
    han_su_dung = '2026-01-01'
WHERE voucher_ID = 300;

-- Đơn 200 KHÔNG dùng voucher (để test case hủy đơn không có voucher)
UPDATE ORDERS
SET trang_thai = N'đang giao'
WHERE order_ID = 200;

UPDATE VOUCHER
SET order_ID = NULL
WHERE order_ID = 200;
```

> Sau khi test xong, nếu cần reset về ban đầu thì tự thêm câu `UPDATE` / `ROLLBACK` phù hợp với DB của nhóm.

---

### A.1. TC1 – Hủy đơn có voucher còn hạn → Voucher được hoàn

- **Mục tiêu**: Kiểm tra khi đơn có voucher còn hạn đổi trạng thái sang `hủy` thì voucher được trả lại (không còn gắn với đơn).

**Bước chuẩn bị (nếu cần reset lại)**

```sql
UPDATE ORDERS
SET trang_thai = N'đang giao'
WHERE order_ID = 102;

UPDATE VOUCHER
SET order_ID = 102,
    han_su_dung = '2026-01-01'
WHERE voucher_ID = 300;
```

**Action (thao tác test)**

```sql
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 102;
```

**Expected (kết quả mong đợi)**

```sql
SELECT voucher_ID, order_ID, han_su_dung
FROM VOUCHER
WHERE voucher_ID = 300;
```

- `order_ID` của voucher 300 phải = `NULL` (voucher được hoàn).  
- Nếu đúng → **PASS**, ngược lại → **FAIL**.

---

### A.2. TC2 – Hủy đơn nhưng voucher đã hết hạn → Không hoàn

- **Mục tiêu**: Hết hạn sử dụng thì trigger **không hoàn** voucher.

**Precondition**

```sql
UPDATE VOUCHER
SET han_su_dung = '2023-01-01',  -- ngày trong quá khứ
    order_ID = 102
WHERE voucher_ID = 300;

UPDATE ORDERS
SET trang_thai = N'đang giao'
WHERE order_ID = 102;
```

**Action**

```sql
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 102;
```

**Expected**

```sql
SELECT voucher_ID, order_ID, han_su_dung
FROM VOUCHER
WHERE voucher_ID = 300;
```

- `order_ID` **vẫn = 102** (voucher không được hoàn).  
- Nếu voucher bị set `NULL` → trigger sai → **FAIL**.

---

### A.3. TC3 – Đơn vốn đã = “hủy”, update lại → Không hoàn (idempotent)

- **Mục tiêu**: Cập nhật lại cùng trạng thái `hủy` **không làm thay đổi voucher**.

**Precondition**

```sql
-- Cho đơn 102 đã ở trạng thái hủy, voucher vẫn gắn
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 102;

UPDATE VOUCHER
SET order_ID = 102,
    han_su_dung = '2026-01-01'
WHERE voucher_ID = 300;
```

**Action**

```sql
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 102;
```

**Expected**

```sql
SELECT voucher_ID, order_ID
FROM VOUCHER
WHERE voucher_ID = 300;
```

- `order_ID` **giữ nguyên = 102**, không bị set `NULL`.  
- Nếu có thay đổi → trigger xử lý sai điều kiện `FROM != 'hủy' TO 'hủy'`.

---

### A.4. TC4 – Đơn thay đổi từ “đang giao” → “đã giao” → Không hoàn

- **Mục tiêu**: Trigger **chỉ chạy khi đổi sang `hủy`**, các trạng thái khác không ảnh hưởng voucher.

**Precondition**

```sql
UPDATE ORDERS
SET trang_thai = N'đang giao'
WHERE order_ID = 102;

UPDATE VOUCHER
SET order_ID = 102,
    han_su_dung = '2026-01-01'
WHERE voucher_ID = 300;
```

**Action**

```sql
UPDATE ORDERS
SET trang_thai = N'đã giao'
WHERE order_ID = 102;
```

**Expected**

```sql
SELECT voucher_ID, order_ID
FROM VOUCHER
WHERE voucher_ID = 300;
```

- `order_ID` vẫn = 102.  
- Nếu voucher bị set `NULL` → trigger đang bắt sai điều kiện.

---

### A.5. TC5 – Hủy đơn không dùng voucher → Trigger chạy nhưng không update gì

- **Mục tiêu**: Nếu đơn **không có voucher**, trigger không làm ảnh hưởng gì tới bảng `VOUCHER`.

**Precondition**

```sql
UPDATE ORDERS
SET trang_thai = N'đang giao'
WHERE order_ID = 200;

-- Đảm bảo không có voucher nào gắn với order_ID = 200
UPDATE VOUCHER
SET order_ID = NULL
WHERE order_ID = 200;

SELECT * FROM VOUCHER WHERE order_ID = 200; -- Kỳ vọng: 0 dòng
```

**Action**

```sql
UPDATE ORDERS
SET trang_thai = N'hủy'
WHERE order_ID = 200;
```

**Expected**

```sql
SELECT * FROM VOUCHER WHERE order_ID = 200;
```

- Kết quả query phải **không có bản ghi nào** (0 dòng).  
- Nếu có bản ghi mới hoặc dòng nào bị update sai → trigger xử lý dư.

---

## PHẦN B – TRIGGER CẬP NHẬT RATING TRUNG BÌNH MÓN ĂN

### B.0. Chuẩn bị dữ liệu mẫu

Giả sử cấu trúc tối thiểu:

- `FOOD(food_ID, Ten_mon, Diem_danh_gia, ...)`
- `RATING(rating_ID, customer_ID, food_ID, Noi_dung, Diem_danh_gia, order_ID, ...)`

Tạo 1 món test và đảm bảo không có rating cũ (hoặc xóa hết):

```sql
-- Food test có ID = 10
UPDATE FOOD
SET Diem_danh_gia = 5
WHERE food_ID = 10;

DELETE FROM RATING
WHERE food_ID = 10;

-- Thêm 1 món khác để test ảnh hưởng chéo
UPDATE FOOD
SET Diem_danh_gia = 5
WHERE food_ID = 11;

DELETE FROM RATING
WHERE food_ID = 11;
```

---

### B.1. TC1 – Insert rating đầu tiên cho food → Tính đúng

- **Mục tiêu**: Khi thêm rating đầu tiên, `Diem_danh_gia` của món = chính điểm vừa insert.

**Action**

```sql
INSERT INTO RATING (rating_ID, customer_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES (900, 1, 10, N'Ngon', 4);
```

**Expected**

```sql
SELECT food_ID, Diem_danh_gia
FROM FOOD
WHERE food_ID = 10;
```

- `Diem_danh_gia` của món 10 phải = **4**.

---

### B.2. TC2 – Thêm rating thứ 2 → Tính trung bình đúng

- **Mục tiêu**: Kiểm tra lại AVG sau khi có 2 bản ghi rating.

**Action**

```sql
INSERT INTO RATING (rating_ID, customer_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES (901, 2, 10, N'Bình thường', 2);
```

**Expected**

```sql
SELECT food_ID, Diem_danh_gia
FROM FOOD
WHERE food_ID = 10;
```

- `Diem_danh_gia` = (4 + 2) / 2 = **3.0**.

---

### B.3. TC3 – Update một rating → AVG thay đổi

- **Mục tiêu**: Khi sửa một rating, AVG phải được tính lại đúng.

**Action**

```sql
UPDATE RATING
SET Diem_danh_gia = 5
WHERE rating_ID = 901 AND food_ID = 10;
```

**Expected**

```sql
SELECT food_ID, Diem_danh_gia
FROM FOOD
WHERE food_ID = 10;
```

- AVG mới = (4 + 5) / 2 = **4.5**.

---

### B.4. TC4 – Xóa hết rating của food → Điểm reset = 5

- **Mục tiêu**: Khi không còn rating nào, `Diem_danh_gia` phải quay về giá trị default = 5.

**Action**

```sql
DELETE FROM RATING
WHERE food_ID = 10;
```

**Expected**

```sql
SELECT food_ID, Diem_danh_gia
FROM FOOD
WHERE food_ID = 10;
```

- `Diem_danh_gia` = **5**.

---

### B.5. TC5 – Insert rating cho food khác → Không ảnh hưởng món đang test

- **Mục tiêu**: Rating của món khác **không làm thay đổi** `Diem_danh_gia` món 10.

**Action**

```sql
INSERT INTO RATING (rating_ID, customer_ID, food_ID, Noi_dung, Diem_danh_gia)
VALUES (950, 1, 11, N'OK', 4);
```

**Expected**

```sql
SELECT food_ID, Diem_danh_gia
FROM FOOD
WHERE food_ID IN (10, 11);
```

- `Diem_danh_gia` của món 10 **không đổi** so với trước khi insert.  
- Chỉ món 11 cập nhật AVG theo các rating của chính nó.

---

## PHẦN C – HƯỚNG DẪN TEST TRÊN WEB (NẾU NHÓM CÓ GIAO DIỆN)

Giả sử web của nhóm có các chức năng:

- Cập nhật trạng thái đơn hàng
- Thêm / sửa / xóa đánh giá món
- Xem điểm trung bình từng món
- Xem danh sách voucher của người dùng

Các bạn có thể map từng testcase SQL ở trên sang flow trên web như sau.

### C.1. Trigger hoàn voucher – Flow trên web

**Chuẩn bị chung**

- Login bằng user có **đơn 102 đang dùng voucher 300**.  
- Vào trang **Chi tiết đơn hàng** và ghi nhận: trạng thái đơn, voucher đang gắn.

**TC A.1 – Hủy đơn voucher còn hạn**

1. Vào chi tiết đơn 102.  
2. Nhấn nút **"Hủy đơn"**. Backend sẽ `UPDATE ORDERS.trang_thai = N'hủy'`.  
3. Sau khi hủy xong, vào trang **"Voucher của tôi"**.
4. Kiểm tra:
   - Voucher 300 xuất hiện lại trong danh sách voucher khả dụng.  
   - Trên DB: `VOUCHER.order_ID` của voucher 300 = `NULL`.

**TC A.2 – Hủy đơn nhưng voucher đã hết hạn**

1. Trên DB, chỉnh `han_su_dung` của voucher 300 về ngày quá khứ.  
2. Trên web, vào đơn 102 và bấm **"Hủy đơn"**.  
3. Kiểm tra:
   - Đơn bị hủy (OK).  
   - Voucher 300 **không xuất hiện** lại trong danh sách voucher khả dụng.  
   - Trên DB: `VOUCHER.order_ID` vẫn = 102.

### C.2. Trigger rating – Flow trên web

**Flow thêm rating (tương ứng B.1, B.2)**

1. Vào trang chi tiết Food 10. Ghi nhận điểm trung bình hiện tại.  
2. Mở màn hình **"Đánh giá món"**.  
3. Chọn số sao (ví dụ 4 sao), nhập nội dung, bấm Gửi.  
4. Reload trang món: điểm trung bình phải cập nhật đúng theo công thức AVG.

**Flow sửa rating (tương ứng B.3)**

1. Vào **"Lịch sử đánh giá"** của user.  
2. Chọn đánh giá đã tạo cho món 10, bấm **"Sửa"**.  
3. Đổi điểm (ví dụ từ 2 sao → 5 sao), lưu lại.  
4. Vào lại trang món 10, kiểm tra điểm trung bình đã tăng / giảm đúng.

**Flow xóa rating (tương ứng B.4)**

1. Vào **"Lịch sử đánh giá"**, bấm **"Xóa"** các đánh giá của món 10.  
2. Nếu còn rating khác → điểm trung bình tính lại theo số rating còn lại.  
3. Nếu xóa rating cuối cùng → `Diem_danh_gia` của món 10 trên giao diện phải về 5.

**Kiểm tra ảnh hưởng chéo (tương ứng B.5)**

1. Vào món 11, thêm / sửa / xóa rating.  
2. Đảm bảo khi reload danh sách món, **điểm của món 10 không đổi** khi chỉ thao tác trên món 11.