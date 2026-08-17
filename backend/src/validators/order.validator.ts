import { z } from 'zod';

export const createOrderSchema = z.object({
  body: z.object({
    clientName: z.string().min(2, 'Client Name is required'),
    clientPhone: z.string().optional().nullable(),
    organization: z.string().optional().nullable(),
    clientAddress: z.string().optional().nullable(),
    clientGstNumber: z.string().optional().nullable(),
    pincode: z.string().min(1, 'Pincode is required'),
    state: z.string().min(2, 'State is required'),
    deliveryDate: z.string().datetime({ message: 'Delivery Date must be a valid ISO timestamp' }),
    shippingCharge: z.number().min(0).default(0),
    advanceAmount: z.number().min(0).default(0),
    mockupUrl: z.string().url().optional().nullable(),
    priority: z.string().optional(),
    products: z.array(
      z.object({
        productCode: z.string().optional().nullable(),
        productName: z.string().min(1, 'Product Name is required'),
        sizeDescription: z.string().optional().nullable(),
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

export const updateOrderSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid order ID'),
  }),
  body: z.object({
    clientName: z.string().min(2).optional(),
    clientPhone: z.string().optional().nullable(),
    organization: z.string().optional().nullable(),
    clientAddress: z.string().optional().nullable(),
    clientGstNumber: z.string().optional().nullable(),
    pincode: z.string().optional().nullable(),
    state: z.string().optional().nullable(),
    deliveryDate: z.string().datetime().optional(),
    shippingCharge: z.number().min(0).optional(),
    advanceAmount: z.number().min(0).optional(),
    mockupUrl: z.string().url().optional().nullable(),
    product_details: z.string().optional().nullable(),
    productDetails: z.string().optional().nullable(),
    quantity: z.number().int().positive().optional(),
    total_amount: z.number().min(0).optional(),
    totalAmount: z.number().min(0).optional(),
    balance_due: z.number().optional(),
    balanceDue: z.number().optional(),
    status: z.string().optional(),
    products: z.array(
      z.object({
        productCode: z.string().optional().nullable(),
        productName: z.string().min(1),
        sizeDescription: z.string().optional().nullable(),
        qty: z.number().int().positive(),
        price: z.number().min(0),
        gstPercentage: z.number().min(0).default(0),
        neckType: z.string().optional(),
        productType: z.string().optional(),
        color: z.string().optional(),
        fabricType: z.string().optional(),
      })
    ).optional(),
  }),
});

export const updateOrderStatusSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid order ID'),
  }),
  body: z.object({
    status: z.string().min(1, 'Status is required'),
    stage: z.string().optional(),
    remark: z.string().optional(),
    last_updated_by: z.string().optional(),
    lastUpdatedBy: z.string().optional(),
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
