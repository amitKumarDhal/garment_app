import { supabaseAdmin } from '../config/supabase.config';

export class PaymentRepository {
  async findAllPending() {
    const { data, error } = await supabaseAdmin
      .from('payment_requests')
      .select('*')
      .eq('status', 'pending')
      .order('requested_at', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async createRequest(requestData: Record<string, any>) {
    const { data, error } = await supabaseAdmin
      .from('payment_requests')
      .insert(requestData)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async updateStatus(id: string, status: 'approved' | 'rejected', approvedById: string) {
    const { data, error } = await supabaseAdmin
      .from('payment_requests')
      .update({
        status,
        approved_at: new Date().toISOString(),
        approved_by_id: approvedById,
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }
}
