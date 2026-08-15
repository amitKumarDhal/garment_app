import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export const envConfig = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || '*',

  supabase: {
    url: process.env.SUPABASE_URL || 'https://mock-yoobbel-supabase.co',
    anonKey: process.env.SUPABASE_ANON_KEY || 'mock-anon-key',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || 'mock-service-role-key',
  },

  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || 'yoobbel-media',
    apiKey: process.env.CLOUDINARY_API_KEY || '123456789012345',
    apiSecret: process.env.CLOUDINARY_API_SECRET || 'mock-secret',
    uploadPreset: process.env.CLOUDINARY_UPLOAD_PRESET || 'yoobbel_production_preset',
  },

  initialAdmin: {
    email: process.env.INITIAL_ADMIN_EMAIL || 'admin@yoobbel.com',
    password: process.env.INITIAL_ADMIN_PASSWORD || 'SuperSecureAdminPass2026!',
    name: process.env.INITIAL_ADMIN_NAME || 'Super Admin',
  },
};
