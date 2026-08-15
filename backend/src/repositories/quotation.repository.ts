import { supabaseAdmin } from '../config/supabase.config';

export class QuotationRepository {
  async findAll() {
    const { data, error } = await supabaseAdmin
      .from('quotations')
      .select('*, quotation_items(*)')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async createQuotationWithItems(quotationData: Record<string, any>, items: any[]) {
    // Insert header first
    const { data: quote, error: quoteErr } = await supabaseAdmin
      .from('quotations')
      .insert(quotationData)
      .select()
      .single();

    if (quoteErr) throw quoteErr;

    // Attach quotation_id to items and bulk insert
    const itemsData = items.map((item) => ({
      ...item,
      quotation_id: quote.id,
    }));

    const { data: insertedItems, error: itemsErr } = await supabaseAdmin
      .from('quotation_items')
      .insert(itemsData)
      .select();

    if (itemsErr) throw itemsErr;

    return { ...quote, items: insertedItems };
  }
}
