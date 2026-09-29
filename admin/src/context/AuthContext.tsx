import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../api/client';

export interface AdminUser {
  id: string;
  email: string;
  fullName?: string | null;
  role: string;
  isAdmin: boolean;
}

interface AuthContextType {
  adminUser: AdminUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const savedToken = localStorage.getItem('admin_token');
    const savedUser = localStorage.getItem('admin_user');

    if (savedToken && savedUser) {
      try {
        const user = JSON.parse(savedUser);
        if (user.role === 'ADMIN' || user.isAdmin === true) {
          setToken(savedToken);
          setAdminUser(user);
        } else {
          localStorage.removeItem('admin_token');
          localStorage.removeItem('admin_user');
        }
      } catch {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (email: string, password: string): Promise<void> => {
    const res = await api.post('/api/v1/auth/login', { email, password });
    if (!res.success || !res.data) {
      throw new Error(res.message || 'Login failed');
    }

    const { user, accessToken } = res.data;
    const isAdmin = user.role === 'ADMIN' || user.isAdmin === true;

    if (!isAdmin) {
      throw new Error('Access denied. Administrator privileges required to access CMS.');
    }

    const adminProfile: AdminUser = {
      id: user.id,
      email: user.email,
      fullName: user.fullName || user.name,
      role: user.role || 'ADMIN',
      isAdmin: true,
    };

    localStorage.setItem('admin_token', accessToken);
    localStorage.setItem('admin_user', JSON.stringify(adminProfile));

    setToken(accessToken);
    setAdminUser(adminProfile);
  };

  const logout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setToken(null);
    setAdminUser(null);
    window.location.href = '/login';
  };

  return (
    <AuthContext.Provider
      value={{
        adminUser,
        token,
        isAuthenticated: Boolean(token && adminUser),
        isLoading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
