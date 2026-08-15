import { supabaseAdmin } from '../config/supabase.config';

export class OrderRepository {
  async findAll(filters: { marketingPersonId?: string; status?: string[]; isDeleted?: boolean } = {}) {
    let query = supabaseAdmin.from('orders').select('*, order_items(*), stage_histories(*)');

    if (filters.isDeleted !== undefined) {
      query = query.eq('is_deleted', filters.isDeleted);
    } else {
      query = query.eq('is_deleted', false);
    }

    if (filters.marketingPersonId) {
      query = query.eq('marketing_person_id', filters.marketingPersonId);
    }

    if (filters.status && filters.status.length > 0) {
      query = query.in('status', filters.status);
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async findById(id: string) {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .select('*, order_items(*), stage_histories(*)')
      .eq('id', id)
      .single();
    if (error) return null;
    return data;
  }

  async createOrderWithItems(orderData: Record<string, any>, items: any[]) {
    // 1. Insert order header
    const { data: order, error: orderErr } = await supabaseAdmin
      .from('orders')
      .insert(orderData)
      .select()
      .single();

    if (orderErr) throw orderErr;

    // 2. Insert order items
    const formattedItems = items.map((item) => ({
      order_id: order.id,
      product_code: item.productCode || null,
      product_name: item.productName,
      size_description: item.sizeDescription || null,
      qty: item.qty,
      price: item.price,
      gst_percentage: item.gstPercentage || 0,
      total: (item.qty * item.price) * (1 + (item.gstPercentage || 0) / 100),
      neck_type: item.neckType || 'Not Specified',
      product_type: item.productType || 'Not Specified',
      color: item.color || 'Not Specified',
      fabric_type: item.fabricType || 'Not Specified',
    }));

    const { data: insertedItems, error: itemsErr } = await supabaseAdmin
      .from('order_items')
      .insert(formattedItems)
      .select();

    if (itemsErr) throw itemsErr;

    // 3. Initial stage history log
    await supabaseAdmin.from('stage_histories').insert({
      order_id: order.id,
      stage: order.status,
      updated_by: order.marketing_person_name,
    });

    return { ...order, items: insertedItems };
  }

  async updateStatus(id: string, status: string, updatedBy: string, extraFields: Record<string, any> = {}) {
    const { data: updatedOrder, error } = await supabaseAdmin
      .from('orders')
      .update({
        status,
        last_updated_by: updatedBy,
        updated_at: new Date().toISOString(),
        ...extraFields,
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // Record stage history event
    await supabaseAdmin.from('stage_histories').insert({
      order_id: id,
      stage: status,
      updated_by: updatedBy,
    });

    return updatedOrder;
  }

  async requestDeletion(id: string) {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .update({ is_delete_requested: true, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  }
}
