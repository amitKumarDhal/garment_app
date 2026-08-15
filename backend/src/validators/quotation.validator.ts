import { z } from 'zod';

export const createQuotationSchema = z.object({
  body: z.object({
    clientName: z.string().min(2, 'Client Name is required'),
    clientAddress: z.string().optional(),
    clientGst: z.string().optional(),
    shipping: z.number().min(0).default(0),
    items: z.array(
      z.object({
        name: z.string().min(1, 'Item description is required'),
        price: z.number().min(0, 'Price must be non-negative'),
        quantity: z.number().int().positive('Quantity must be greater than 0'),
        gstPercent: z.number().min(0).default(0),
      })
    ).min(1, 'Quotation must have at least one item'),
  }),
});
