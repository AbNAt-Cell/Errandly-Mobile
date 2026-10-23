import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://errandly-web-yob65x-3fabb8-169-58-145-66.sslip.io/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    let token = localStorage.getItem('errand_token');
    if (!token) {
      try {
        const stored = localStorage.getItem('errand-auth');
        if (stored) {
          const parsed = JSON.parse(stored);
          token = parsed?.state?.token;
          if (token) {
            localStorage.setItem('errand_token', token);
          }
        }
      } catch {
        // ignore
      }
    }
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const url = error.config?.url || '';
      // Don't wipe session on login attempts or if already on auth screens
      if (!url.includes('/auth/login') && !url.includes('/auth/register')) {
        if (typeof window !== 'undefined' && !window.location.pathname.startsWith('/auth/')) {
          localStorage.removeItem('errand_token');
          localStorage.removeItem('errand_user');
          try {
            localStorage.removeItem('errand-auth');
          } catch {
            // ignore
          }
          window.location.href = '/auth/login';
        }
      }
    }
    return Promise.reject(error);
  }
);

export default api;

// Auth
export const authApi = {
  registerCustomer: (data: any) => api.post('/auth/register/customer', data),
  registerRunner: (data: any) => api.post('/auth/register/runner', data),
  login: (data: any) => api.post('/auth/login', data),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/auth/me'),
  updateProfile: (data: any) => api.put('/auth/profile', data),
  changePassword: (data: any) => api.put('/auth/password', data),
  forgotPassword: (data: any) => api.post('/auth/forgot-password', data),
  resetPassword: (data: any) => api.post('/auth/reset-password', data),
  verifyPhone: (data: any) => api.post('/auth/verify-phone', data),
  resendOtp: () => api.post('/auth/resend-otp'),
};

// Customer
export const customerApi = {
  dashboard: () => api.get('/customer/dashboard'),
  savedAddresses: () => api.get('/customer/saved-addresses'),
  addAddress: (data: any) => api.post('/customer/saved-addresses', data),
  deleteAddress: (id: number) => api.delete(`/customer/saved-addresses/${id}`),
  errands: (params?: any) => api.get('/customer/errands', { params }),
  createErrand: (data: any) => api.post('/customer/errands', data),
  getErrand: (publicId: string) => api.get(`/customer/errands/${publicId}`),
  cancelErrand: (publicId: string, reason: string) => api.post(`/customer/errands/${publicId}/cancel`, { reason }),
  confirmCompletion: (publicId: string, otp: string) => api.post(`/customer/errands/${publicId}/confirm-completion`, { otp }),
  trackErrand: (publicId: string) => api.get(`/customer/errands/${publicId}/tracking`),
  panic: (publicId: string, data: any) => api.post(`/customer/errands/${publicId}/panic`, data),
  getProof: (publicId: string) => api.get(`/customer/errands/${publicId}/proof`),
  verifyErrandPayment: (publicId: string, reference?: string, gateway?: string) => 
    api.post(`/customer/errands/${publicId}/verify-payment`, { reference, gateway }),
  initializeErrandPayment: (publicId: string, data?: { payment_method?: 'paystack' | 'bach' | 'wallet'; frontend_url?: string }) =>
    api.post(`/customer/errands/${publicId}/pay`, data),
  initPayment: (data: { amount: number; gateway?: 'paystack' | 'bach' | 'flutterwave' | 'stripe'; channels?: string[] }) =>
    api.post('/customer/payments/initialize', data),
  verifyPayment: (data: { reference: string; gateway?: string; gateway_transaction_id?: string }) =>
    api.post('/customer/payments/verify', data),
  gateways: () => api.get('/customer/payments/gateways'),
};

// Runner
export const runnerApi = {
  dashboard: () => api.get('/runner/dashboard'),
  updateAvailability: (data: any) => api.put('/runner/availability', data),
  updateLocation: (data: any) => api.put('/runner/location', data),
  availableErrands: (params?: any) => api.get('/runner/errands/available', { params }),
  myErrands: (params?: any) => api.get('/runner/errands/my-errands', { params }),
  getErrand: (publicId: string) => api.get(`/runner/errands/${publicId}`),
  acceptErrand: (publicId: string) => api.post(`/runner/errands/${publicId}/accept`),
  rejectErrand: (publicId: string) => api.post(`/runner/errands/${publicId}/reject`),
  markArrived: (publicId: string) => api.post(`/runner/errands/${publicId}/arrived`),
  verifyPickupOtp: (publicId: string, otp: string) => api.post(`/runner/errands/${publicId}/pickup-otp`, { otp }),
  startErrand: (publicId: string) => api.post(`/runner/errands/${publicId}/start`),
  submitProof: (publicId: string, data: any) => api.post(`/runner/errands/${publicId}/proof`, data),
  cancelErrand: (publicId: string, reason: string) => api.post(`/runner/errands/${publicId}/cancel`, { reason }),
  updateErrandLocation: (publicId: string, data: any) => api.put(`/runner/errands/${publicId}/location`, data),
  earnings: () => api.get('/runner/earnings'),
  withdraw: (amount: number) => api.post('/runner/earnings/withdraw', { amount }),
  trustScore: () => api.get('/runner/trust-score'),
  stats: () => api.get('/runner/stats'),
  verificationStatus: () => api.get('/runner/verification-status'),
  submitKyc: (data: any) => api.post('/runner/kyc/submit', data),
  updateBankAccount: (data: any) => api.put('/runner/earnings/bank-account', data),
  panic: (publicId: string, data: any) => api.post(`/runner/errands/${publicId}/panic`, data),
};

// Wallet
export const walletApi = {
  get: () => api.get('/wallet'),
  transactions: (params?: any) => api.get('/wallet/transactions', { params }),
  fund: (data: any) => api.post('/wallet/fund', data),
  verifyPayment: (data: any) => api.post('/wallet/verify-payment', data),
  gateways: () => api.get('/customer/payments/gateways'),
};

// Uploads
export const uploadApi = {
  upload: (file: File | Blob, folder: string = 'chat', filename?: string) => {
    const formData = new FormData();
    if (file instanceof File) {
      formData.append('file', file);
    } else {
      formData.append('file', file, filename || 'recording.webm');
    }
    formData.append('folder', folder);
    return api.post('/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
};

// Messages
export const messageApi = {
  conversations: () => api.get('/messages/conversations'),
  getConversation: (publicId: string) => api.get(`/messages/conversations/${publicId}`),
  send: (publicId: string, data: any) => api.post(`/messages/conversations/${publicId}`, data),
  sendVoice: (publicId: string, data: { media_url: string; duration_seconds: number }) =>
    api.post(`/messages/conversations/${publicId}/voice`, data),
  markRead: (publicId: string) => api.put(`/messages/conversations/${publicId}/read`),
};

// Ratings
export const ratingApi = {
  submit: (data: any) => api.post('/ratings', data),
  myRatings: () => api.get('/ratings/my-ratings'),
};

// Disputes
export const disputeApi = {
  list: () => api.get('/disputes'),
  create: (data: any) => api.post('/disputes', data),
  get: (id: number) => api.get(`/disputes/${id}`),
  addEvidence: (id: number, data: any) => api.post(`/disputes/${id}/evidence`, data),
};

// KYC
export const kycApi = {
  status: () => api.get('/kyc'),
  submit: (data: any) => api.post('/kyc/submit', data),
  resubmit: (data: any) => api.post('/kyc/resubmit', data),
};

// Notifications
export const notificationApi = {
  list: () => api.get('/notifications'),
  markRead: (id: number) => api.put(`/notifications/${id}/read`),
  markAllRead: () => api.put('/notifications/read-all'),
};

// AI assistant
export const aiApi = {
  chat: (data: { message: string; session_id?: string; context?: Record<string, unknown> }) =>
    api.post('/ai/agent', data),
  confirm: (data: { proposal_id: string; confirmation_token: string }) =>
    api.post('/ai/confirm', data),
  parseErrandText: (text: string) => api.post('/ai/errands/parse-text', { text }),
  parseErrandImage: (imageUrl: string, notes?: string) =>
    api.post('/ai/errands/parse-image', { image_url: imageUrl, notes }),
  parseErrandAudio: (audioUrl: string, notes?: string) =>
    api.post('/ai/errands/parse-audio', { audio_url: audioUrl, notes }),
  proposeCreate: (data: Record<string, unknown>) => api.post('/ai/errands/propose', data),
  confirmErrand: (data: { proposal_id: string; confirmation_token: string }) =>
    api.post('/ai/errands/confirm', data),
  suggestBudget: (data: Record<string, unknown>) => api.post('/ai/errands/suggest-budget', data),
  normalizeAddress: (freeText: string, city?: string) =>
    api.post('/ai/errands/normalize-address', { free_text: freeText, city }),
  suggestTemplate: (hint?: string) =>
    api.get('/ai/errands/suggest-template', { params: hint ? { hint } : {} }),
  searchPolicy: (query: string) => api.get('/ai/policy/search', { params: { query } }),
};

// Admin
export const adminApi = {
  dashboard: () => api.get('/admin/dashboard'),
  metrics: (params?: any) => api.get('/admin/metrics', { params }),
  liveMap: () => api.get('/admin/live-map'),
  users: (params?: any) => api.get('/admin/users', { params }),
  getUser: (id: number) => api.get(`/admin/users/${id}`),
  suspendUser: (id: number, data: any) => api.put(`/admin/users/${id}/suspend`, data),
  restoreUser: (id: number) => api.put(`/admin/users/${id}/restore`),
  blacklistUser: (id: number, data: any) => api.put(`/admin/users/${id}/blacklist`, data),
  runners: (params?: any) => api.get('/admin/runners', { params }),
  approveRunner: (id: number) => api.put(`/admin/runners/${id}/approve`),
  kycList: (params?: any) => api.get('/admin/kyc', { params }),
  kycPending: () => api.get('/admin/kyc/pending'),
  kycGet: (id: number) => api.get(`/admin/kyc/${id}`),
  kycApprove: (id: number, data?: any) => api.put(`/admin/kyc/${id}/approve`, data),
  kycReject: (id: number, data: any) => api.put(`/admin/kyc/${id}/reject`, data),
  kycResubmit: (id: number, data: any) => api.put(`/admin/kyc/${id}/request-resubmission`, data),
  errands: (params?: any) => api.get('/admin/errands', { params }),
  getErrand: (publicId: string) => api.get(`/admin/errands/${publicId}`),
  assignErrand: (publicId: string, data: { runner_id: number; reason?: string }) =>
    api.post(`/admin/errands/${publicId}/assign`, data),
  reassignErrand: (publicId: string, data: any) => api.post(`/admin/errands/${publicId}/reassign`, data),
  cancelErrand: (publicId: string, data: any) => api.post(`/admin/errands/${publicId}/cancel`, data),
  finance: () => api.get('/admin/finance/overview'),
  escrow: () => api.get('/admin/finance/escrow'),
  refund: (data: any) => api.post('/admin/finance/refund', data),
  freezeWallet: (userId: number) => api.put(`/admin/finance/wallets/${userId}/freeze`),
  disputes: (params?: any) => api.get('/admin/disputes', { params }),
  dispute: (id: number) => api.get(`/admin/disputes/${id}`),
  resolveDispute: (id: number, data: any) => api.post(`/admin/disputes/${id}/resolve`, data),
  summarizeDispute: (id: number) => api.post(`/admin/ai/disputes/${id}/summarize`),
  disputeAiAnalysis: (id: number) => api.get(`/admin/ai/disputes/${id}/analysis`),
  errandAiInsights: (publicId: string) => api.get(`/admin/ai/errands/${publicId}/insights`),
  kycAiAnalysis: (id: number) => api.get(`/admin/ai/kyc/${id}/analysis`),
  reports: {
    revenue: (params?: any) => api.get('/admin/reports/revenue', { params }),
    errands: (params?: any) => api.get('/admin/reports/errands', { params }),
    users: (params?: any) => api.get('/admin/reports/users', { params }),
  },
  settings: () => api.get('/admin/settings'),
  updateSettings: (data: any) => api.put('/admin/settings', data),
  broadcast: (data: { title: string; body: string; role?: string; city?: string }) =>
    api.post('/admin/notifications/broadcast', data),
};

// Public Configuration
export const configApi = {
  get: () => api.get('/config'),
};

// In-App WebRTC Voice Calls
export const callApi = {
  initiate: (data: { errand_id: string | number; offer_sdp: string; type?: 'audio' | 'video' }) =>
    api.post('/calls/initiate', data),
  answer: (callId: string, data: { answer_sdp: string }) =>
    api.post(`/calls/${callId}/answer`, data),
  signal: (callId: string, data: { candidate: any }) =>
    api.post(`/calls/${callId}/signal`, data),
  end: (callId: string, data?: { reason?: string }) =>
    api.post(`/calls/${callId}/end`, data || {}),
  reject: (callId: string, data?: { reason?: string }) =>
    api.post(`/calls/${callId}/reject`, data || {}),
  getCall: (callId: string) =>
    api.get(`/calls/${callId}`),
};

