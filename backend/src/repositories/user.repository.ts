import { supabaseAdmin } from '../config/supabase.config';

export class UserRepository {
  async findById(id: string) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', id)
      .single();
    if (error) return null;
    return data;
  }

  async findByEmail(email: string) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('email', email)
      .single();
    if (error) return null;
    return data;
  }

  async findPending() {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('status', 'PENDING')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async createProfile(profileData: {
    id: string;
    name: string;
    email: string;
    employee_id?: string;
    role: string;
    status: string;
  }) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .insert(profileData)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async updateApproval(id: string, updates: Record<string, any>) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async deleteUser(id: string) {
    // Delete from public.users table and Supabase auth.users
    await supabaseAdmin.from('users').delete().eq('id', id);
    const { error } = await supabaseAdmin.auth.admin.deleteUser(id);
    if (error) throw error;
    return true;
  }
}
