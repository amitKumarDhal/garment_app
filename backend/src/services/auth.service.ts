import { supabaseAdmin, supabaseClient } from '../config/supabase.config';
import { UserRepository } from '../repositories/user.repository';
import { ApiError } from '../utils/apiError';

export class AuthService {
  private userRepo = new UserRepository();

  async registerUser(data: {
    name: string;
    email: string;
    password: string;
    employeeId?: string;
    role: string;
  }) {
    // 1. Check if profile already exists in public.users
    const existing = await this.userRepo.findByEmail(data.email);
    if (existing) {
      throw ApiError.conflict('User with this email already exists');
    }

    // 2. Create user in Supabase Auth (auth.users)
    const { data: authData, error: authErr } = await supabaseAdmin.auth.admin.createUser({
      email: data.email,
      password: data.password,
      email_confirm: true,
      user_metadata: { name: data.name, role: data.role },
    });

    if (authErr || !authData.user) {
      throw ApiError.badRequest(authErr?.message || 'Failed to create auth user');
    }

    // 3. Create profile in public.users with status PENDING
    const profile = await this.userRepo.createProfile({
      id: authData.user.id,
      name: data.name,
      email: data.email,
      employee_id: data.employeeId,
      role: data.role,
      status: 'PENDING',
    });

    return profile;
  }

  async loginUser(email: string, pass: string) {
    // 1. Sign in via Supabase Auth
    const { data: authData, error } = await supabaseClient.auth.signInWithPassword({
      email,
      password: pass,
    });

    if (error || !authData.session) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    // 2. Fetch profile from public.users
    const profile = await this.userRepo.findById(authData.user.id);
    if (!profile) {
      throw ApiError.unauthorized('User profile not found');
    }

    if (profile.status !== 'APPROVED') {
      throw ApiError.forbidden(`Your account registration is ${profile.status}. Admin approval is required.`);
    }

    return {
      accessToken: authData.session.access_token,
      refreshToken: authData.session.refresh_token,
      expiresAt: authData.session.expires_at,
      user: {
        id: profile.id,
        name: profile.name,
        email: profile.email,
        role: profile.role,
        agentRank: profile.agent_rank || 'JSA',
        status: profile.status,
      },
    };
  }

  async refreshToken(token: string) {
    if (!token) {
      throw ApiError.badRequest('Refresh token is required');
    }

    // 1. Refresh Supabase session
    const { data: authData, error } = await supabaseClient.auth.refreshSession({
      refresh_token: token,
    });

    if (error || !authData.session || !authData.user) {
      throw ApiError.unauthorized('Invalid or expired refresh token');
    }

    // 2. Fetch user profile from database
    const profile = await this.userRepo.findById(authData.user.id);
    if (!profile) {
      throw ApiError.unauthorized('User profile not found');
    }

    if (profile.status !== 'APPROVED') {
      throw ApiError.forbidden(`Your account registration is ${profile.status}. Admin approval is required.`);
    }

    return {
      accessToken: authData.session.access_token,
      refreshToken: authData.session.refresh_token,
      expiresAt: authData.session.expires_at,
      user: {
        id: profile.id,
        name: profile.name,
        email: profile.email,
        role: profile.role,
        agentRank: profile.agent_rank || 'JSA',
        status: profile.status,
      },
    };
  }
}
