import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { authApi } from '@/lib/api';

interface User {
  id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  phone: string;
  profile_image?: string;
  status: string;
  kyc_status: string;
  roles: string[];
  runner_profile?: any;
  wallet_balance?: number;
}

interface AuthState {
  user: User | null;
  token: string | null;
  roles: string[];
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: { login: string; password: string }) => Promise<void>;
  logout: () => void;
  setUser: (user: User) => void;
  establishSession: (payload: { user: User; token: string; roles: string[] }) => void;
  refreshUser: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      roles: [],
      isAuthenticated: false,
      isLoading: false,

      login: async (credentials) => {
        set({ isLoading: true });
        try {
          const response = await authApi.login(credentials);
          const { user, token, roles } = response.data;

          localStorage.setItem('errandly_token', token);

          set({
            user: { ...user, roles },
            token,
            roles,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error) {
          set({ isLoading: false });
          throw error;
        }
      },

      logout: async () => {
        try {
          await authApi.logout();
        } catch {}
        localStorage.removeItem('errandly_token');
        localStorage.removeItem('errandly_user');
        set({ user: null, token: null, roles: [], isAuthenticated: false });
      },

      setUser: (user) => set({ user }),

      establishSession: ({ user, token, roles }) => {
        localStorage.setItem('errandly_token', token);
        set({
          user: { ...user, roles },
          token,
          roles,
          isAuthenticated: true,
        });
      },

      refreshUser: async () => {
        try {
          const response = await authApi.me();
          const { user, roles } = response.data;
          set({ user: { ...user, roles }, roles, isAuthenticated: true });
        } catch {
          get().logout();
        }
      },
    }),
    {
      name: 'errandly-auth',
      partialize: (state) => ({
        token: state.token,
        user: state.user,
        roles: state.roles,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);

export const useIsRole = (role: string) => {
  const roles = useAuthStore((s) => s.roles);
  return roles.includes(role);
};

export const useIsAdmin = () => useIsRole('admin') || useIsRole('super_admin');
export const useIsCustomer = () => useIsRole('customer');
export const useIsRunner = () => useIsRole('runner');
