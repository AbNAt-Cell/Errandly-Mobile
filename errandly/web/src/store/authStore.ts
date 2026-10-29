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
  _hasHydrated: boolean;
  setHasHydrated: (state: boolean) => void;
  login: (credentials: { login: string; password: string }) => Promise<void>;
  googleLogin: (idToken: string, role?: string) => Promise<any>;
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
      _hasHydrated: false,

      setHasHydrated: (state: boolean) => set({ _hasHydrated: state }),

      login: async (credentials) => {
        set({ isLoading: true });
        try {
          const response = await authApi.login(credentials);
          const { user, token, roles } = response.data;

          if (typeof window !== 'undefined') {
            localStorage.setItem('errand_token', token);
            localStorage.setItem('errand_user', JSON.stringify(user));
          }

          set({
            user: { ...user, roles },
            token,
            roles,
            isAuthenticated: true,
            isLoading: false,
            _hasHydrated: true,
          });
        } catch (error) {
          set({ isLoading: false });
          throw error;
        }
      },

      googleLogin: async (idToken: string, role?: string) => {
        set({ isLoading: true });
        try {
          const response = await authApi.googleLogin({ id_token: idToken, role: role || 'customer' });
          const { user, token, roles } = response.data;

          if (typeof window !== 'undefined') {
            localStorage.setItem('errand_token', token);
            localStorage.setItem('errand_user', JSON.stringify(user));
          }

          set({
            user: { ...user, roles },
            token,
            roles,
            isAuthenticated: true,
            isLoading: false,
            _hasHydrated: true,
          });
          return response.data;
        } catch (error) {
          set({ isLoading: false });
          throw error;
        }
      },

      logout: async () => {
        try {
          await authApi.logout();
        } catch {}
        if (typeof window !== 'undefined') {
          localStorage.removeItem('errand_token');
          localStorage.removeItem('errand_user');
          try {
            localStorage.removeItem('errand-auth');
          } catch {}
        }
        set({ user: null, token: null, roles: [], isAuthenticated: false });
      },

      setUser: (user) => {
        if (typeof window !== 'undefined') {
          localStorage.setItem('errand_user', JSON.stringify(user));
        }
        set({ user });
      },

      establishSession: ({ user, token, roles }) => {
        if (typeof window !== 'undefined') {
          localStorage.setItem('errand_token', token);
          localStorage.setItem('errand_user', JSON.stringify(user));
        }
        set({
          user: { ...user, roles },
          token,
          roles,
          isAuthenticated: true,
          _hasHydrated: true,
        });
      },

      refreshUser: async () => {
        try {
          const response = await authApi.me();
          const { user, roles } = response.data;
          if (typeof window !== 'undefined') {
            localStorage.setItem('errand_user', JSON.stringify(user));
          }
          set({ user: { ...user, roles }, roles, isAuthenticated: true });
        } catch {
          get().logout();
        }
      },
    }),
    {
      name: 'errand-auth',
      onRehydrateStorage: () => (state) => {
        if (state) {
          if (typeof window !== 'undefined') {
            if (state.token) {
              localStorage.setItem('errand_token', state.token);
            }
            if (state.user) {
              localStorage.setItem('errand_user', JSON.stringify(state.user));
            }
          }
          state.setHasHydrated(true);
        }
      },
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
