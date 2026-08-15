import { supabaseAdmin } from '../config/supabase.config';

export class InventoryRepository {
  async findAllItems() {
    const { data, error } = await supabaseAdmin
      .from('inventory_items')
      .select('*')
      .order('fabric_type', { ascending: true });
    if (error) throw error;
    return data || [];
  }

  async findByFabricAndColor(fabricType: string, color: string) {
    const { data, error } = await supabaseAdmin
      .from('inventory_items')
      .select('*')
      .ilike('fabric_type', fabricType.trim())
      .ilike('color', color.trim())
      .maybeSingle();
    if (error) throw error;
    return data;
  }

  async findAllTransactions(limit = 200) {
    const { data, error } = await supabaseAdmin
      .from('inventory_transactions')
      .select('*')
      .order('timestamp', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return data || [];
  }

  async recordTransaction(
    fabricType: string,
    color: string,
    action: 'IN' | 'OUT' | 'ADJUSTMENT',
    quantity: number,
    addedBy: string,
    unit = 'KG'
  ) {
    // 1. Check or Create Inventory Item
    let item = await this.findByFabricAndColor(fabricType, color);
    
    if (!item) {
      if (action === 'OUT') {
        throw new Error(`Fabric '${fabricType}' (${color}) not found in inventory.`);
      }
      const { data: newItem, error: createErr } = await supabaseAdmin
        .from('inventory_items')
        .insert({
          name: `${fabricType} (${color})`,
          fabric_type: fabricType.trim(),
          color: color.trim(),
          unit,
          quantity: 0,
        })
        .select()
        .single();
      if (createErr) throw createErr;
      item = newItem;
    }

    // 2. Stock calculation
    const currentStock = Number(item.quantity);
    let newStock = currentStock;

    if (action === 'IN') {
      newStock += quantity;
    } else if (action === 'OUT') {
      if (currentStock < quantity) {
        throw new Error(`Insufficient stock! Available: ${currentStock} ${unit}, Required: ${quantity} ${unit}`);
      }
      newStock -= quantity;
    } else if (action === 'ADJUSTMENT') {
      newStock = quantity;
    }

    // 3. Update stock in inventory_items
    const { error: updateErr } = await supabaseAdmin
      .from('inventory_items')
      .update({ quantity: newStock, updated_at: new Date().toISOString() })
      .eq('id', item.id);

    if (updateErr) throw updateErr;

    // 4. Record transaction log
    const { data: transaction, error: logErr } = await supabaseAdmin
      .from('inventory_transactions')
      .insert({
        inventory_item_id: item.id,
        fabric_type: fabricType.trim(),
        color: color.trim(),
        action,
        quantity,
        unit,
        added_by: addedBy,
      })
      .select()
      .single();

    if (logErr) throw logErr;

    return transaction;
  }
}
