import { supabaseAdmin } from '../config/supabase.config';

export class ProductRepository {
  async findAll() {
    const { data, error } = await supabaseAdmin
      .from('products')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true });
    if (error) throw error;
    return data || [];
  }

  async create(productData: Record<string, any>) {
    const { data, error } = await supabaseAdmin
      .from('products')
      .insert(productData)
      .select()
      .single();
    if (error) throw error;
    return data;
  }
}
