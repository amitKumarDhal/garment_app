import { z } from 'zod';

export const inventoryTransactionSchema = z.object({
  body: z.object({
    fabricType: z.string().min(1, 'Fabric type is required'),
    color: z.string().min(1, 'Color is required'),
    action: z.enum(['IN', 'OUT', 'ADJUSTMENT']),
    quantity: z.number().positive('Quantity must be positive'),
    unit: z.enum(['KG', 'PCS', 'METERS']).default('KG'),
  }),
});
