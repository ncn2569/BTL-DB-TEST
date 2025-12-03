// FE/Form/users-improved-example.js
// Đây là VÍ DỤ về cách cải thiện users.js với các tính năng mới
// So sánh với file users.js gốc để thấy sự khác biệt

const API_BASE = '/api';

// ========================== CRUD USERS ==========================
let editMode = false;
let editingUserId = null;
let currentUsers = []; // Lưu users hiện tại để export

// Gọi API lấy danh sách users
async function loadUsers(search = '') {
  const tableBody = document.querySelector('#users-table tbody');
  
  // ✨ IMPROVEMENT: Dùng loading spinner thay vì text
  createLoadingSpinner(tableBody, 'Đang tải danh sách users...');

  try {
    const res = await fetch(`${API_BASE}/users?search=${encodeURIComponent(search)}`);
    const data = await res.json();

    if (!data.success) {
      throw new Error(data.message || 'Lỗi API');
    }

    currentUsers = data.data || [];
    
    if (!currentUsers || currentUsers.length === 0) {
      // ✨ IMPROVEMENT: Dùng empty state đẹp
      showEmptyState(tableBody, 'Không tìm thấy user nào', '👤');
      return;
    }

    displayUsers(currentUsers);

  } catch (err) {
    console.error(err);
    // ✨ IMPROVEMENT: Dùng toast notification
    toast.error('Lỗi khi tải danh sách users: ' + err.message);
    showEmptyState(tableBody, 'Đã xảy ra lỗi khi tải dữ liệu', '❌');
  }
}

function displayUsers(users) {
  const tableBody = document.querySelector('#users-table tbody');
  tableBody.innerHTML = '';

  users.forEach((u, index) => {
    const tr = document.createElement('tr');
    // ✨ IMPROVEMENT: Thêm animation delay cho từng row
    tr.style.animationDelay = `${index * 0.05}s`;
    tr.classList.add('fade-in');
    
    tr.innerHTML = `
      <td>${u.ID}</td>
      <td>${u.Ho_ten}</td>
      <td>${u.Email}</td>
      <td>${u.SDT || ''}</td>
      <td>${u.TKNH || ''}</td>
      <td>${u.Dia_chi || ''}</td>
      <td>
        <button class="btn-edit action-btn edit" data-id="${u.ID}" title="Sửa user">
          ✏️ Sửa
        </button>
        <button class="btn-delete action-btn delete" data-id="${u.ID}" title="Xóa user">
          🗑️ Xóa
        </button>
      </td>
    `;
    tableBody.appendChild(tr);
  });

  // Gắn event cho nút Sửa / Xóa
  document.querySelectorAll('.btn-edit').forEach(btn => {
    btn.addEventListener('click', () => startEditUser(btn.dataset.id));
  });

  document.querySelectorAll('.btn-delete').forEach(btn => {
    btn.addEventListener('click', () => deleteUser(btn.dataset.id));
  });
}

// ✨ IMPROVEMENT: Real-time validation function
function setupRealTimeValidation() {
  // Email validation
  const emailInput = document.getElementById('user-email');
  emailInput.addEventListener('blur', function() {
    validateField(this, validateEmail, 'Email không hợp lệ');
  });
  
  emailInput.addEventListener('input', function() {
    if (this.value && validateEmail(this.value)) {
      this.closest('.form-group').classList.remove('has-error');
      this.closest('.form-group').classList.add('has-success');
    }
  });

  // Phone validation
  const phoneInput = document.getElementById('user-sdt');
  phoneInput.addEventListener('blur', function() {
    validateField(this, validatePhone, 'Số điện thoại phải có 10 số và bắt đầu bằng 0');
  });

  // Password validation
  const passwordInput = document.getElementById('user-password');
  passwordInput.addEventListener('input', function() {
    if (this.value) {
      const result = validatePassword(this.value);
      const formGroup = this.closest('.form-group');
      
      if (result.valid) {
        formGroup.classList.remove('has-error');
        formGroup.classList.add('has-success');
      } else {
        formGroup.classList.add('has-error');
        formGroup.classList.remove('has-success');
        showFieldError(formGroup, result.message);
      }
    }
  });

  // Bank account validation
  const bankInput = document.getElementById('user-tknh');
  bankInput.addEventListener('blur', function() {
    const value = this.value.trim();
    const formGroup = this.closest('.form-group');
    
    if (!value) {
      formGroup.classList.remove('has-success');
      return;
    }
    
    if (/^[0-9]{10,16}$/.test(value)) {
      formGroup.classList.remove('has-error');
      formGroup.classList.add('has-success');
    } else {
      formGroup.classList.add('has-error');
      formGroup.classList.remove('has-success');
      showFieldError(formGroup, 'Tài khoản ngân hàng phải có 10-16 chữ số');
    }
  });
}

function validateField(input, validator, errorMessage) {
  const formGroup = input.closest('.form-group');
  const value = input.value.trim();
  
  if (!value && input.required) {
    formGroup.classList.add('has-error');
    formGroup.classList.remove('has-success');
    showFieldError(formGroup, 'Trường này là bắt buộc');
    return false;
  }
  
  if (value && !validator(value)) {
    formGroup.classList.add('has-error');
    formGroup.classList.remove('has-success');
    showFieldError(formGroup, errorMessage);
    return false;
  }
  
  if (value && validator(value)) {
    formGroup.classList.remove('has-error');
    formGroup.classList.add('has-success');
    clearFieldError(formGroup);
    return true;
  }
  
  return true;
}

function showFieldError(formGroup, message) {
  let errorDiv = formGroup.querySelector('.validation-message');
  if (!errorDiv) {
    errorDiv = document.createElement('div');
    errorDiv.className = 'validation-message';
    formGroup.appendChild(errorDiv);
  }
  errorDiv.textContent = message;
}

function clearFieldError(formGroup) {
  const errorDiv = formGroup.querySelector('.validation-message');
  if (errorDiv) {
    errorDiv.remove();
  }
}

// Bắt đầu edit: fill form với dữ liệu hàng được chọn
function startEditUser(id) {
  const row = [...document.querySelectorAll('#users-table tbody tr')]
    .find(tr => tr.children[0].textContent === String(id));

  if (!row) return;

  const [idCell, nameCell, emailCell, sdtCell, tknhCell, diachiCell] = row.children;

  document.getElementById('user-id').value = idCell.textContent;
  document.getElementById('user-id').disabled = true;
  document.getElementById('user-hoten').value = nameCell.textContent;
  document.getElementById('user-email').value = emailCell.textContent;
  document.getElementById('user-sdt').value = sdtCell.textContent;
  document.getElementById('user-tknh').value = tknhCell.textContent;
  document.getElementById('user-diachi').value = diachiCell.textContent;
  document.getElementById('user-password').value = '';
  document.getElementById('user-password').required = false;

  editMode = true;
  editingUserId = id;
  document.getElementById('user-form-title').textContent = 'Cập nhật user';
  document.getElementById('user-submit-btn').textContent = 'Lưu thay đổi';
  document.getElementById('user-cancel-edit-btn').style.display = 'inline-block';
  
  // ✨ IMPROVEMENT: Smooth scroll to form
  document.getElementById('user-form').scrollIntoView({ 
    behavior: 'smooth', 
    block: 'start' 
  });
  
  // ✨ IMPROVEMENT: Toast notification
  toast.info('Đã tải thông tin user. Vui lòng chỉnh sửa và lưu.');
}

// Hủy chế độ edit -> quay về create
function cancelEditUser() {
  editMode = false;
  editingUserId = null;
  document.getElementById('user-id').disabled = false;
  document.getElementById('user-form').reset();
  document.getElementById('user-form-title').textContent = 'Thêm user mới';
  document.getElementById('user-submit-btn').textContent = 'Tạo mới';
  document.getElementById('user-cancel-edit-btn').style.display = 'none';
  document.getElementById('user-password').required = true;
  
  // ✨ IMPROVEMENT: Clear all validation states
  document.querySelectorAll('.form-group').forEach(group => {
    group.classList.remove('has-error', 'has-success');
    clearFieldError(group);
  });
  
  // ✨ IMPROVEMENT: Toast notification
  toast.info('Đã hủy chỉnh sửa');
}

// Submit form create/update
async function handleUserFormSubmit(e) {
  e.preventDefault();

  if (!validateUserForm()) {
    return;
  }

  const id = document.getElementById('user-id').value;
  const hoten = document.getElementById('user-hoten').value.trim();
  const email = document.getElementById('user-email').value.trim();
  const sdt = document.getElementById('user-sdt').value.trim();
  const password = document.getElementById('user-password').value;
  const tknh = document.getElementById('user-tknh').value.trim();
  const diachi = document.getElementById('user-diachi').value.trim();

  const payload = {
    ID: parseInt(id, 10),
    Ho_ten: hoten,
    Email: email,
    SDT: sdt,
    Password: password || undefined,
    TKNH: tknh,
    Dia_chi: diachi
  };

  // ✨ IMPROVEMENT: Show loading on submit button
  const submitBtn = document.getElementById('user-submit-btn');
  const originalText = submitBtn.textContent;
  submitBtn.disabled = true;
  submitBtn.textContent = 'Đang xử lý...';

  try {
    let url = `${API_BASE}/users`;
    let method = 'POST';

    if (editMode && editingUserId) {
      url = `${API_BASE}/users/${editingUserId}`;
      method = 'PUT';
      delete payload.ID;
    }

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await res.json();
    if (!data.success) {
      const errorMsg = data.error || data.message || 'Lỗi không xác định';
      throw new Error(errorMsg);
    }

    // ✨ IMPROVEMENT: Toast notification với message rõ ràng
    toast.success(
      editMode 
        ? 'Cập nhật user thành công!' 
        : 'Thêm user mới thành công!'
    );
    
    cancelEditUser();
    
    // Tải lại danh sách
    const searchValue = document.getElementById('user-search-input').value || '';
    await loadUsers(searchValue);

  } catch (err) {
    console.error(err);
    // ✨ IMPROVEMENT: Toast error với message chi tiết
    toast.error('Lỗi: ' + err.message);
  } finally {
    // ✨ IMPROVEMENT: Restore button state
    submitBtn.disabled = false;
    submitBtn.textContent = originalText;
  }
}

// Validate form data (giữ nguyên logic)
function validateUserForm() {
  // ... (giữ nguyên validation logic)
  return true;
}

// Xóa user
async function deleteUser(id) {
  const userName = [...document.querySelectorAll('#users-table tbody tr')]
    .find(tr => tr.children[0].textContent === String(id))?.children[1]?.textContent || id;

  // ✨ IMPROVEMENT: Dùng custom confirm dialog
  const confirmed = await showConfirmDialog(
    `Bạn có chắc chắn muốn xóa user "${userName}" (ID: ${id})?\n\nLưu ý: Nếu user này đã có đơn hàng hoặc liên quan đến dữ liệu khác, việc xóa có thể thất bại.`,
    'Xác nhận xóa user',
    'Xóa',
    'Hủy'
  );
  
  if (!confirmed) {
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/users/${id}`, {
      method: 'DELETE'
    });
    const data = await res.json();

    if (!data.success) {
      const errorMsg = data.error || data.message || 'Lỗi không xác định';
      throw new Error(errorMsg);
    }

    // ✨ IMPROVEMENT: Toast notification
    toast.success(`Đã xóa user "${userName}" thành công!`);
    
    const searchValue = document.getElementById('user-search-input').value || '';
    await loadUsers(searchValue);

  } catch (err) {
    console.error(err);
    // ✨ IMPROVEMENT: Toast error
    toast.error('Lỗi khi xóa: ' + err.message);
  }
}

// ✨ NEW FEATURE: Export to CSV
function exportUsersToCSV() {
  if (!currentUsers || currentUsers.length === 0) {
    toast.warning('Không có dữ liệu để xuất!');
    return;
  }

  const headers = ['ID', 'Họ tên', 'Email', 'SĐT', 'TKNH', 'Địa chỉ'];
  const filename = `users_${new Date().toISOString().split('T')[0]}.csv`;
  
  exportToCSV(currentUsers, filename, headers);
  toast.success(`Đã xuất ${currentUsers.length} user ra file CSV!`);
}

// ========================== DOMContentLoaded ==========================
document.addEventListener('DOMContentLoaded', () => {
  // Load users khi trang load
  loadUsers();

  // ✨ IMPROVEMENT: Setup real-time validation
  setupRealTimeValidation();

  // Form submit
  document.getElementById('user-form').addEventListener('submit', handleUserFormSubmit);
  
  // Cancel edit
  document.getElementById('user-cancel-edit-btn').addEventListener('click', cancelEditUser);

  // ✨ IMPROVEMENT: Debounced search để tối ưu performance
  const searchInput = document.getElementById('user-search-input');
  const debouncedSearch = debounce((searchTerm) => {
    loadUsers(searchTerm);
  }, 300);
  
  searchInput.addEventListener('input', (e) => {
    debouncedSearch(e.target.value);
  });

  // Search button (vẫn giữ cho UX)
  document.getElementById('user-search-btn').addEventListener('click', () => {
    const search = searchInput.value || '';
    loadUsers(search);
  });

  // Search on Enter
  searchInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      document.getElementById('user-search-btn').click();
    }
  });

  // Refresh
  document.getElementById('user-refresh-btn').addEventListener('click', () => {
    searchInput.value = '';
    loadUsers('');
    toast.info('Đã tải lại danh sách');
  });

  // ✨ NEW FEATURE: Export button (nếu có trong HTML)
  const exportBtn = document.getElementById('export-users-btn');
  if (exportBtn) {
    exportBtn.addEventListener('click', exportUsersToCSV);
  }
});


