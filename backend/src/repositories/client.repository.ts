import { supabaseAdmin } from '../config/supabase.config';

export class ClientRepository {
  async findAll() {
    const { data, error } = await supabaseAdmin
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async findById(id: string) {
    const { data, error } = await supabaseAdmin
      .from('clients')
      .select('*')
      .eq('id', id)
      .single();
    if (error) return null;
    return data;
  }

  async create(clientData: Record<string, any>) {
    const { data, error } = await supabaseAdmin
      .from('clients')
      .insert(clientData)
      .select()
      .single();
    if (error) throw error;
    return data;
  }
}
