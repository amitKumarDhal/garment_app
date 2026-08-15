import { QuotationRepository } from '../repositories/quotation.repository';
import { ApiError } from '../utils/apiError';

export class QuotationService {
  private quoteRepo = new QuotationRepository();

  async getQuotations() {
    return this.quoteRepo.findAll();
  }

  async createQuotation(data: {
    clientName: string;
    clientAddress?: string;
    clientGst?: string;
    shipping?: number;
    items: Array<{ name: string; price: number; quantity: number; gstPercent?: number }>;
  }, userId: string) {
    if (!data.items || data.items.length === 0) {
      throw ApiError.badRequest('Quotation must contain at least one item');
    }

    // SERVER-SIDE FINANCIAL MATH VALIDATION
    let subTotal = 0;
    let totalGst = 0;

    const validatedItems = data.items.map((item) => {
      const price = Number(item.price) || 0;
      const qty = Number(item.quantity) || 1;
      const gstPct = Number(item.gstPercent) || 0;

      const base = price * qty;
      const gst = base * (gstPct / 100);

      subTotal += base;
      totalGst += gst;

      return {
        name: item.name.trim(),
        price,
        quantity: qty,
        gst_percent: gstPct,
        item_total: base + gst,
      };
    });

    const shipping = Number(data.shipping) || 0;
    const grandTotal = subTotal + totalGst + shipping;

    const quotationHeader = {
      client_name: data.clientName.trim(),
      client_address: data.clientAddress?.trim() || null,
      client_gst: data.clientGst?.trim() || null,
      sub_total: subTotal,
      total_gst: totalGst,
      shipping,
      grand_total: grandTotal,
      status: 'Draft',
      created_by_id: userId,
    };

    return this.quoteRepo.createQuotationWithItems(quotationHeader, validatedItems);
  }
}
