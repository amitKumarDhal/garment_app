import { z } from 'zod';

export const createOrderSchema = z.object({
  body: z.object({
    clientName: z.string().min(2, 'Client Name is required'),
    clientPhone: z.string().optional(),
    organization: z.string().optional(),
    clientAddress: z.string().optional(),
    clientGstNumber: z.string().optional(),
    pincode: z.string().length(6, 'Pincode must be 6 digits'),
    state: z.string().min(2, 'State is required'),
    deliveryDate: z.string().datetime({ message: 'Delivery Date must be a valid ISO timestamp' }),
    shippingCharge: z.number().min(0).default(0),
    advanceAmount: z.number().min(0).default(0),
    mockupUrl: z.string().url().optional().nullable(),
    products: z.array(
      z.object({
        productCode: z.string().optional(),
        productName: z.string().min(1, 'Product Name is required'),
        sizeDescription: z.string().optional(),
        qty: z.number().int().positive('Quantity must be greater than 0'),
        price: z.number().min(0, 'Price cannot be negative'),
        gstPercentage: z.number().min(0).default(0),
        neckType: z.string().optional(),
        productType: z.string().min(1, 'Category/Product Type is required'),
        color: z.string().optional(),
        fabricType: z.string().min(1, 'Fabric Type is required'),
      })
    ).min(1, 'Order must contain at least one product item'),
  }),
});

export const approveOrderSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid order ID'),
  }),
  body: z.object({
    effectiveRevenue: z.number().optional(),
    marginNumber: z.number().optional(),
    approvalNotes: z.string().optional(),
  }),
});
