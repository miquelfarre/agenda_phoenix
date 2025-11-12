import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

export interface TestUser {
  id: number;
  name: string;
  phone: string;
  type: 'private' | 'public';
  username?: string;
}

// Default test users from init_db_2.py
export const TEST_USERS: TestUser[] = [
  // Private users (ID 1-10 - Family)
  { id: 1, name: 'Sonia Martínez', phone: '+34600000001', type: 'private' },
  { id: 2, name: 'Miquel Farré', phone: '+34600000002', type: 'private' },
  { id: 3, name: 'Ada Martínez', phone: '+34600000003', type: 'private' },
  { id: 4, name: 'Sara Rodríguez', phone: '+34600000004', type: 'private' },
  { id: 5, name: 'Pere Martínez', phone: '+34600000005', type: 'private' },
  { id: 6, name: 'Carmen López', phone: '+34600000006', type: 'private' },
  { id: 7, name: 'Joan García', phone: '+34600000007', type: 'private' },
  { id: 8, name: 'Maria Sánchez', phone: '+34600000008', type: 'private' },
  { id: 9, name: 'Marc Torres', phone: '+34600000009', type: 'private' },
  { id: 10, name: 'Laura Pérez', phone: '+34600000010', type: 'private' },

  // Public users (ID 86-100 - Organizations)
  { id: 86, name: 'FC Barcelona', phone: '+34600000086', type: 'public', username: '@fcbarcelona' },
  { id: 87, name: 'Teatro Nacional Catalunya', phone: '+34600000087', type: 'public', username: '@teatrebarcelona' },
  { id: 88, name: 'Gimnasio FitZone', phone: '+34600000088', type: 'public', username: '@fitzonegym' },
  { id: 89, name: 'Restaurante El Buen Sabor', phone: '+34600000089', type: 'public', username: '@saborcatalunya' },
  { id: 90, name: 'Museo Picasso', phone: '+34600000090', type: 'public', username: '@museupicasso' },
  { id: 91, name: 'Festes de la Mercè', phone: '+34600000091', type: 'public', username: '@festivalmerce' },
  { id: 92, name: 'Green Point Yoga', phone: '+34600000092', type: 'public', username: '@greenpointbcn' },
  { id: 93, name: 'Barcelona Tech Hub', phone: '+34600000093', type: 'public', username: '@techbarcelona' },
  { id: 94, name: 'Cines Verdi', phone: '+34600000094', type: 'public', username: '@cinemaverdi' },
  { id: 95, name: 'La Birreria', phone: '+34600000095', type: 'public', username: '@labirreria' },
  { id: 96, name: 'Casa Batlló', phone: '+34600000096', type: 'public', username: '@casabatllo' },
  { id: 97, name: 'Primavera Sound', phone: '+34600000097', type: 'public', username: '@primaverasound' },
  { id: 98, name: 'Mercat Gòtic', phone: '+34600000098', type: 'public', username: '@marketgoticbcn' },
  { id: 99, name: 'Climbat Escalada', phone: '+34600000099', type: 'public', username: '@escaladabcn' },
  { id: 100, name: 'Libreria Laie', phone: '+34600000100', type: 'public', username: '@librerialaie' },
];

class APIClient {
  private client: AxiosInstance;
  private currentUser: TestUser | null = null;

  constructor(baseURL: string = 'http://localhost:8001') {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add request interceptor to include user ID
    this.client.interceptors.request.use((config) => {
      if (this.currentUser) {
        config.headers['X-Test-User-Id'] = this.currentUser.id.toString();
      }
      return config;
    });
  }

  setUser(user: TestUser) {
    this.currentUser = user;
  }

  getCurrentUser(): TestUser | null {
    return this.currentUser;
  }

  async get<T = any>(url: string, config?: AxiosRequestConfig) {
    const response = await this.client.get<T>(url, config);
    return response.data;
  }

  async post<T = any>(url: string, data?: any, config?: AxiosRequestConfig) {
    const response = await this.client.post<T>(url, data, config);
    return response.data;
  }

  async put<T = any>(url: string, data?: any, config?: AxiosRequestConfig) {
    const response = await this.client.put<T>(url, data, config);
    return response.data;
  }

  async delete<T = any>(url: string, config?: AxiosRequestConfig) {
    const response = await this.client.delete<T>(url, config);
    return response.data;
  }

  async patch<T = any>(url: string, data?: any, config?: AxiosRequestConfig) {
    const response = await this.client.patch<T>(url, data, config);
    return response.data;
  }

  // Raw request for full control
  async request<T = any>(config: AxiosRequestConfig) {
    const response = await this.client.request<T>(config);
    return {
      data: response.data,
      status: response.status,
      headers: response.headers,
    };
  }
}

export const apiClient = new APIClient();
