// FE/Form/utils.js
// Utility functions for better UX

// Toast Notification System
class ToastManager {
  constructor() {
    this.container = null;
    this.init();
  }

  init() {
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.className = 'toast-container';
      document.body.appendChild(this.container);
    }
  }

  show(message, type = 'info', duration = 4000) {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    
    const icon = this.getIcon(type);
    toast.innerHTML = `
      <div class="toast-icon">${icon}</div>
      <div class="toast-message">${message}</div>
      <button class="toast-close" onclick="this.parentElement.remove()">×</button>
    `;
    
    this.container.appendChild(toast);
    
    // Animate in
    setTimeout(() => toast.classList.add('show'), 10);
    
    // Auto remove
    if (duration > 0) {
      setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
      }, duration);
    }
    
    return toast;
  }

  getIcon(type) {
    const icons = {
      success: '✓',
      error: '✕',
      warning: '⚠',
      info: 'ℹ'
    };
    return icons[type] || icons.info;
  }

  success(message, duration) {
    return this.show(message, 'success', duration);
  }

  error(message, duration) {
    return this.show(message, 'error', duration);
  }

  warning(message, duration) {
    return this.show(message, 'warning', duration);
  }

  info(message, duration) {
    return this.show(message, 'info', duration);
  }
}

// Global toast instance
const toast = new ToastManager();

// Loading Spinner Component
function createLoadingSpinner(container, message = 'Đang tải...') {
  const spinner = document.createElement('div');
  spinner.className = 'loading-spinner-wrapper';
  spinner.innerHTML = `
    <div class="loading-spinner">
      <div class="spinner"></div>
      <p>${message}</p>
    </div>
  `;
  
  if (container) {
    container.innerHTML = '';
    container.appendChild(spinner);
  }
  
  return spinner;
}

// Better Confirm Dialog
function showConfirmDialog(message, title = 'Xác nhận', confirmText = 'Xác nhận', cancelText = 'Hủy') {
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    
    const dialog = document.createElement('div');
    dialog.className = 'confirm-dialog';
    dialog.innerHTML = `
      <div class="confirm-dialog-header">
        <h3>${title}</h3>
      </div>
      <div class="confirm-dialog-body">
        <p>${message}</p>
      </div>
      <div class="confirm-dialog-footer">
        <button class="btn btn-secondary" data-action="cancel">${cancelText}</button>
        <button class="btn btn-primary" data-action="confirm">${confirmText}</button>
      </div>
    `;
    
    overlay.appendChild(dialog);
    document.body.appendChild(overlay);
    
    // Animate in
    setTimeout(() => overlay.classList.add('show'), 10);
    
    const handleClick = (e) => {
      const action = e.target.dataset.action;
      if (action === 'confirm') {
        overlay.classList.remove('show');
        setTimeout(() => overlay.remove(), 300);
        resolve(true);
      } else if (action === 'cancel' || e.target === overlay) {
        overlay.classList.remove('show');
        setTimeout(() => overlay.remove(), 300);
        resolve(false);
      }
    };
    
    overlay.addEventListener('click', handleClick);
  });
}

// Format Vietnamese currency
function formatCurrency(amount) {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount);
}

// Format Vietnamese date
function formatDate(date) {
  if (!date) return '';
  return new Date(date).toLocaleDateString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
}

// Debounce function for search
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Validate email
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Validate phone (Vietnamese format)
function validatePhone(phone) {
  return /^0[0-9]{9}$/.test(phone);
}

// Validate password strength
function validatePassword(password) {
  if (password.length < 8) return { valid: false, message: 'Mật khẩu phải có ít nhất 8 ký tự' };
  if (!/[A-Za-z]/.test(password)) return { valid: false, message: 'Mật khẩu phải có ít nhất 1 chữ cái' };
  if (!/[0-9]/.test(password)) return { valid: false, message: 'Mật khẩu phải có ít nhất 1 chữ số' };
  if (!/[^A-Za-z0-9]/.test(password)) return { valid: false, message: 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt' };
  return { valid: true };
}

// Show empty state
function showEmptyState(container, message = 'Không có dữ liệu', icon = '📭') {
  const emptyState = document.createElement('div');
  emptyState.className = 'empty-state';
  emptyState.innerHTML = `
    <div class="empty-state-icon">${icon}</div>
    <p class="empty-state-message">${message}</p>
  `;
  
  if (container) {
    container.innerHTML = '';
    container.appendChild(emptyState);
  }
  
  return emptyState;
}

// Export to CSV
function exportToCSV(data, filename = 'export.csv', headers = null) {
  let csv = '';
  
  if (headers && Array.isArray(headers)) {
    csv += headers.join(',') + '\n';
  }
  
  data.forEach(row => {
    const values = Object.values(row).map(val => {
      if (typeof val === 'string' && val.includes(',')) {
        return `"${val}"`;
      }
      return val || '';
    });
    csv += values.join(',') + '\n';
  });
  
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// Export functions to window for global use
window.toast = toast;
window.createLoadingSpinner = createLoadingSpinner;
window.showConfirmDialog = showConfirmDialog;
window.formatCurrency = formatCurrency;
window.formatDate = formatDate;
window.debounce = debounce;
window.validateEmail = validateEmail;
window.validatePhone = validatePhone;
window.validatePassword = validatePassword;
window.showEmptyState = showEmptyState;
window.exportToCSV = exportToCSV;


