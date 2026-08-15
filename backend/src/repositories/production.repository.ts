import { supabaseAdmin } from '../config/supabase.config';
import { InventoryRepository } from './inventory.repository';

export class ProductionRepository {
  private inventoryRepo = new InventoryRepository();

  async logCutting(data: {
    orderId?: string;
    styleNo: string;
    lotNo: string;
    fabricType: string;
    consumption: number;
    sizes: Record<string, number>;
    totalQuantity: number;
    addedBy: string;
  }) {
    // 1. Calculate required fabric
    const totalFabricNeeded = data.totalQuantity * data.consumption;

    // 2. Perform Inventory OUT transaction (validates stock & deducts)
    await this.inventoryRepo.recordTransaction(
      data.fabricType,
      'White', // Default color if unspecified
      'OUT',
      totalFabricNeeded,
      data.addedBy,
      'METERS'
    );

    // 3. Create Cutting Entry
    const { data: cuttingEntry, error: cutErr } = await supabaseAdmin
      .from('cutting_entries')
      .insert({
        order_id: data.orderId || null,
        style_no: data.styleNo,
        lot_no: data.lotNo,
        fabric_type: data.fabricType,
        consumption: data.consumption,
        total_fabric_used: totalFabricNeeded,
        sizes: data.sizes,
        total_quantity: data.totalQuantity,
        status: 'Cut Completed',
      })
      .select()
      .single();

    if (cutErr) throw cutErr;

    // 4. Record Activity broadcast
    await supabaseAdmin.from('activities').insert({
      title: `Cutting: ${data.styleNo}`,
      subtitle: `Used ${totalFabricNeeded.toFixed(1)}m of ${data.fabricType}`,
      icon_code: 58835, // Icons.content_cut
      color_value: 0xFF2196F3,
    });

    return cuttingEntry;
  }

  async logPrinting(data: {
    orderId?: string;
    styleNo: string;
    receivedFromCutting: number;
    damagedQuantities: Record<string, number>;
    addedBy: string;
  }) {
    let totalDamaged = 0;
    Object.values(data.damagedQuantities).forEach((val) => {
      totalDamaged += Number(val) || 0;
    });

    const netGoodPieces = data.receivedFromCutting - totalDamaged;

    const { data: printEntry, error } = await supabaseAdmin
      .from('printing_entries')
      .insert({
        order_id: data.orderId || null,
        style_no: data.styleNo,
        received_from_cutting: data.receivedFromCutting,
        damaged_quantities: data.damagedQuantities,
        total_damaged: totalDamaged,
        net_good_pieces: netGoodPieces,
        status: 'Printing Completed',
      })
      .select()
      .single();

    if (error) throw error;

    await supabaseAdmin.from('activities').insert({
      title: `Printing: ${data.styleNo}`,
      subtitle: `${netGoodPieces} OK | ${totalDamaged} Defect`,
      icon_code: 59642, // Icons.print
      color_value: 0xFFFF9800,
    });

    return printEntry;
  }

  async logStitching(data: {
    orderId?: string;
    operator: string;
    styleNo: string;
    operationType: string;
    assignedQty: number;
    completedQty: number;
    rejectedQty: number;
  }) {
    const efficiency = data.assignedQty > 0 ? (data.completedQty / data.assignedQty) * 100 : 0;

    const { data: stitchEntry, error } = await supabaseAdmin
      .from('stitching_entries')
      .insert({
        order_id: data.orderId || null,
        operator: data.operator,
        style_no: data.styleNo,
        operation_type: data.operationType,
        assigned_qty: data.assignedQty,
        completed_qty: data.completedQty,
        rejected_qty: data.rejectedQty,
        efficiency,
        status: 'Stitching Record Added',
      })
      .select()
      .single();

    if (error) throw error;

    await supabaseAdmin.from('activities').insert({
      title: `Stitching: ${data.styleNo}`,
      subtitle: `${data.operator} • ${data.completedQty} Pcs Done`,
      icon_code: 58836,
      color_value: 0xFF009688,
    });

    return stitchEntry;
  }

  async logPacking(data: {
    orderId?: string;
    cartonNo: string;
    styleNo: string;
    category: string;
    totalPieces: number;
    breakdown: Record<string, number>;
  }) {
    const { data: packingEntry, error } = await supabaseAdmin
      .from('packing_entries')
      .insert({
        order_id: data.orderId || null,
        carton_no: data.cartonNo,
        style_no: data.styleNo,
        category: data.category,
        total_pieces: data.totalPieces,
        breakdown: data.breakdown,
        status: 'Packed',
      })
      .select()
      .single();

    if (error) throw error;

    await supabaseAdmin.from('activities').insert({
      title: `Packed: ${data.styleNo}`,
      subtitle: `Carton ${data.cartonNo} (${data.totalPieces} Pcs)`,
      icon_code: 58837,
      color_value: 0xFF795548,
    });

    return packingEntry;
  }

  async findRecentActivities(limit = 20) {
    const { data, error } = await supabaseAdmin
      .from('activities')
      .select('*')
      .order('time', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return data || [];
  }
}
