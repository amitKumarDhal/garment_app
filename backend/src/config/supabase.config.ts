import { createClient } from '@supabase/supabase-js';
import { envConfig } from './env.config';

// 1. Service Role Client (PRIVILEGED SERVER-SIDE OPERATIONAL ACCESS)
// NEVER EXPOSE THIS KEY TO FLUTTER OR FRONTEND
export const supabaseAdmin = createClient(
  envConfig.supabase.url,
  envConfig.supabase.serviceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// 2. Anonymous / Public Client (For JWT verification & Auth operations)
export const supabaseClient = createClient(
  envConfig.supabase.url,
  envConfig.supabase.anonKey
);
