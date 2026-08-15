import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/supabase.config';
import { ApiError } from '../utils/apiError';
import { AuthUser, UserRole, UserStatus, AgentRank } from '../types';

export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Access token is missing or malformed');
    }

    const token = authHeader.split(' ')[1];
    
    // Verify token with Supabase Auth
    const { data: { user: supabaseUser }, error } = await supabaseAdmin.auth.getUser(token);

    if (error || !supabaseUser) {
      throw ApiError.unauthorized('Invalid or expired access token');
    }

    // Fetch user public profile and role from PostgreSQL public.users table
    const { data: userProfile, error: profileError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', supabaseUser.id)
      .single();

    if (profileError || !userProfile) {
      throw ApiError.unauthorized('User profile not found in system database');
    }

    if (userProfile.status !== 'APPROVED') {
      throw ApiError.forbidden(`Account status is ${userProfile.status}. Admin approval required.`);
    }

    req.user = {
      id: userProfile.id,
      email: userProfile.email,
      name: userProfile.name,
      role: userProfile.role as UserRole,
      agentRank: (userProfile.agent_rank || 'JSA') as AgentRank,
      status: userProfile.status as UserStatus,
    };

    next();
  } catch (err) {
    next(err);
  }
};
