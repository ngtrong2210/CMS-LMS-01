export function normalizeApiError(error) {
  const response = error?.response
  return {
    status: response?.status || 0,
    message: response?.data?.message || (response ? 'Không thể xử lý yêu cầu.' : 'Không thể kết nối máy chủ.'),
    errors: response?.data?.errors || [],
  }
}
