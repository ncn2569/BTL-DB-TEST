// FE/Form/restaurant-stats.js
const API_BASE = '/api';
let rsData = []; // lưu dữ liệu để sort lại

// Render bảng từ 1 mảng dữ liệu
function renderRSTable(list) {
  const tbody = document.querySelector('#rs-table tbody');
  tbody.innerHTML = '';

  if (!list || list.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5">Không có dữ liệu.</td></tr>';
    return;
  }

  list.forEach(r => {
    const tr = document.createElement('tr');

    const tongDoanhThu = new Intl.NumberFormat('vi-VN').format(
      parseFloat(r.tong_doanh_thu || 0)
    );
    const giaTriTB = new Intl.NumberFormat('vi-VN', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(parseFloat(r.gia_tri_trung_binh || 0));

    tr.innerHTML = `
      <td>${r.restaurant_ID}</td>
      <td>${r.restaurant_name || ''}</td>
      <td>${r.so_don_hang || 0}</td>
      <td>${tongDoanhThu} đ</td>
      <td>${giaTriTB} đ</td>
    `;
    tbody.appendChild(tr);
  });
}

// Submit form gọi API
async function handleRSForm(e) {
  e.preventDefault();
  const fromDate = document.getElementById('rs-from').value;
  const toDate = document.getElementById('rs-to').value;
  const minTotal = document.getElementById('rs-min').value;
  const msgDiv = document.getElementById('rs-message');

  msgDiv.textContent = '';
  msgDiv.className = 'message';
  msgDiv.style.display = 'none';

  if (!fromDate || !toDate || !minTotal) {
    msgDiv.textContent = 'Vui lòng nhập đầy đủ thông tin.';
    msgDiv.className = 'message error';
    msgDiv.style.display = 'block';
    renderRSTable([]);
    return;
  }

  if (new Date(fromDate) > new Date(toDate)) {
    msgDiv.textContent = 'Ngày bắt đầu phải nhỏ hơn ngày kết thúc.';
    msgDiv.className = 'message error';
    msgDiv.style.display = 'block';
    renderRSTable([]);
    return;
  }

  if (parseFloat(minTotal) < 0) {
    msgDiv.textContent = 'Tổng tối thiểu phải lớn hơn hoặc bằng 0.';
    msgDiv.className = 'message error';
    msgDiv.style.display = 'block';
    renderRSTable([]);
    return;
  }

  try {
    const url =
      `${API_BASE}/stats/restaurantsales` +
      `?fromDate=${fromDate}&toDate=${toDate}&minTotal=${minTotal}`;

    const res = await fetch(url);
    const data = await res.json();

    if (!data.success) throw new Error(data.error || data.message);

    rsData = data.data || [];     // LƯU LẠI dữ liệu để sort
    renderRSTable(rsData);        // hiển thị lần đầu

  } catch (err) {
    console.error(err);
    msgDiv.textContent = 'Lỗi: ' + err.message;
    msgDiv.className = 'message error';
    msgDiv.style.display = 'block';
    renderRSTable([]);
  }
}

// Sort sau khi đã có dữ liệu
function handleRSSort() {
  if (!rsData || rsData.length === 0) return;

  const field = document.getElementById('rs-sort-field').value; // tong_doanh_thu | gia_tri_trung_binh
  const dir = document.getElementById('rs-sort-dir').value;     // asc | desc

  const sorted = [...rsData].sort((a, b) => {
    const aVal = parseFloat(a[field] || 0);
    const bVal = parseFloat(b[field] || 0);
    return dir === 'asc' ? aVal - bVal : bVal - aVal;
  });

  renderRSTable(sorted);
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('rs-form').addEventListener('submit', handleRSForm);
  document.getElementById('rs-sort-btn').addEventListener('click', handleRSSort);
});
