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

  async getLatestOrderSerial(): Promise<{
    lastSerial: number;
    nextSerial: number;
    formattedLastSerial: string;
    formattedNextSerial: string;
  }> {
    // Query all manual_order_no records directly from database
    const { data, error } = await supabaseAdmin
      .from('orders')
      .select('manual_order_no')
      .not('manual_order_no', 'is', null);

    if (error) {
      console.error('[OrderRepository] Error fetching latest order serials:', error);
    }

    const yearPrefix = new Date().getFullYear().toString().slice(-2); // e.g. "26" for 2026
    const defaultStartingSerial = Number(`${yearPrefix}0001`); // 260001

    let maxSerial = 0;
    let lastRawNo = '';

    if (data && data.length > 0) {
      for (const row of data) {
        if (!row.manual_order_no) continue;
        const raw = String(row.manual_order_no).trim();
        // Extract numeric sequence from string (e.g. "ZBR260018" -> "260018", "ZBR005" -> "5")
        const match = raw.match(/\d+/);
        if (match) {
          const num = parseInt(match[0], 10);
          if (!isNaN(num) && num > maxSerial) {
            maxSerial = num;
            lastRawNo = raw;
          }
        }
      }
    }

    let nextSerial: number;
    let formattedLastSerial: string;
    let formattedNextSerial: string;

    if (maxSerial === 0) {
      nextSerial = defaultStartingSerial;
      formattedLastSerial = 'None';
      formattedNextSerial = `ZBR${nextSerial}`;
    } else {
      nextSerial = maxSerial + 1;
      formattedLastSerial = lastRawNo || `ZBR${maxSerial}`;
      if (nextSerial < 1000) {
        formattedNextSerial = `ZBR${String(nextSerial).padStart(3, '0')}`;
      } else {
        formattedNextSerial = `ZBR${nextSerial}`;
      }
    }

    return {
      lastSerial: maxSerial,
      nextSerial,
      formattedLastSerial,
      formattedNextSerial,
    };
  }

  async createOrderWithItems(orderData: Record<string, any>, items: any[]) {
    const maxRetries = 5;
    let attempts = 0;
    let lastErr: any = null;

    while (attempts < maxRetries) {
      attempts++;
      try {
        // Determine authoritative next serial from database if not set or on retry
        if (!orderData.manual_order_no || attempts > 1) {
          const serialInfo = await this.getLatestOrderSerial();
          orderData.manual_order_no = serialInfo.formattedNextSerial;
        }

        // 1. Insert order header
        const { data: order, error: orderErr } = await supabaseAdmin
          .from('orders')
          .insert(orderData)
          .select()
          .single();

        if (orderErr) {
          // Handle unique violation on manual_order_no (PostgreSQL error 23505)
          if (
            orderErr.code === '23505' ||
            orderErr.message?.includes('manual_order_no') ||
            orderErr.message?.includes('duplicate key')
          ) {
            console.warn(
              `[OrderRepository] Conflict on manual_order_no "${orderData.manual_order_no}", retrying attempt ${attempts}...`
            );
            delete orderData.manual_order_no;
            lastErr = orderErr;
            continue;
          }
          throw orderErr;
        }

        // 2. Insert order items
        const formattedItems = items.map((item) => {
          const price = Number(item.price) || 0;
          const qty = Number(item.qty) || 1;
          const gstPct = Number(item.gstPercentage) || 0;
          const itemBase = price * qty;
          const itemGst = itemBase * (gstPct / 100);

          return {
            order_id: order.id,
            product_code: item.productCode || null,
            product_name: item.productName,
            size_description: item.sizeDescription || null,
            qty: qty,
            price: price,
            gst_percentage: gstPct,
            total: itemBase + itemGst,
            neck_type: item.neckType || 'Not Specified',
            product_type: item.productType || 'Not Specified',
            color: item.color || 'Not Specified',
            fabric_type: item.fabricType || 'Not Specified',
          };
        });

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

        return { ...order, order_items: insertedItems };
      } catch (err: any) {
        if (err.code === '23505' && attempts < maxRetries) {
          delete orderData.manual_order_no;
          lastErr = err;
          continue;
        }
        throw err;
      }
    }

    throw lastErr || new Error('Failed to generate a unique order serial after maximum retries');
  }

  async updateOrderWithItems(id: string, orderData: Record<string, any>, items?: any[]) {
    const { data: updatedOrder, error: updateErr } = await supabaseAdmin
      .from('orders')
      .update({
        ...orderData,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (updateErr) throw updateErr;

    if (items && items.length > 0) {
      // Clean delete existing items and insert updated items
      await supabaseAdmin.from('order_items').delete().eq('order_id', id);

      const formattedItems = items.map((item) => {
        const price = Number(item.price) || 0;
        const qty = Number(item.qty) || 1;
        const gstPct = Number(item.gstPercentage) || 0;
        const itemBase = price * qty;
        const itemGst = itemBase * (gstPct / 100);

        return {
          order_id: id,
          product_code: item.productCode || null,
          product_name: item.productName,
          size_description: item.sizeDescription || null,
          qty: qty,
          price: price,
          gst_percentage: gstPct,
          total: itemBase + itemGst,
          neck_type: item.neckType || 'Not Specified',
          product_type: item.productType || 'Not Specified',
          color: item.color || 'Not Specified',
          fabric_type: item.fabricType || 'Not Specified',
        };
      });

      const { data: newItems, error: itemsErr } = await supabaseAdmin
        .from('order_items')
        .insert(formattedItems)
        .select();

      if (itemsErr) throw itemsErr;
      return { ...updatedOrder, order_items: newItems };
    }

    return updatedOrder;
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

  async deleteOrder(id: string, soft = true) {
    if (soft) {
      const { data, error } = await supabaseAdmin
        .from('orders')
        .update({ is_deleted: true, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data;
    } else {
      const { error } = await supabaseAdmin.from('orders').delete().eq('id', id);
      if (error) throw error;
      return { id, deleted: true };
    }
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
