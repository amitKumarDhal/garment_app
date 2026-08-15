import { supabaseAdmin } from '../config/supabase.config';

export class NotificationRepository {
  async findByUserId(targetUserId: string, limit = 30) {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .select('*')
      .eq('target_user_id', targetUserId)
      .order('created_at', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return data || [];
  }

  async getUnreadCount(targetUserId: string) {
    const { count, error } = await supabaseAdmin
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('target_user_id', targetUserId)
      .eq('is_read', false);
    if (error) throw error;
    return count || 0;
  }

  async createNotification(notificationData: {
    target_user_id: string;
    title: string;
    message: string;
    type: string;
    order_id?: string;
  }) {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .insert(notificationData)
      .select()
      .single();
    if (error) throw error;
    return data;
  }

  async markAsRead(id: string, targetUserId: string) {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .eq('target_user_id', targetUserId)
      .select()
      .single();
    if (error) throw error;
    return data;
  }
}
