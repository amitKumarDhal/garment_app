import { z } from 'zod';

export const cuttingEntrySchema = z.object({
  body: z.object({
    orderId: z.string().uuid().optional(),
    styleNo: z.string().min(1, 'Style Number is required'),
    lotNo: z.string().min(1, 'Lot Number is required'),
    fabricType: z.string().min(1, 'Fabric Type is required'),
    consumption: z.number().positive('Consumption must be greater than 0'),
    sizes: z.record(z.string(), z.number().int().min(0)),
    totalQuantity: z.number().int().positive('Total Quantity must be positive'),
  }),
});

export const printingEntrySchema = z.object({
  body: z.object({
    orderId: z.string().uuid().optional(),
    styleNo: z.string().min(1, 'Style Number is required'),
    receivedFromCutting: z.number().int().positive('Received quantity must be positive'),
    damagedQuantities: z.record(z.string(), z.number().int().min(0)),
  }),
});

export const stitchingEntrySchema = z.object({
  body: z.object({
    orderId: z.string().uuid().optional(),
    operator: z.string().min(1, 'Operator name is required'),
    styleNo: z.string().min(1, 'Style Number is required'),
    operationType: z.string().min(1, 'Operation Type is required'),
    assignedQty: z.number().int().positive('Assigned quantity must be positive'),
    completedQty: z.number().int().min(0, 'Completed quantity must be non-negative'),
    rejectedQty: z.number().int().min(0).default(0),
  }),
});

export const packingEntrySchema = z.object({
  body: z.object({
    orderId: z.string().uuid().optional(),
    cartonNo: z.string().min(1, 'Carton Number is required'),
    styleNo: z.string().min(1, 'Style Number is required'),
    category: z.string().default('M'),
    totalPieces: z.number().int().positive('Total pieces must be positive'),
    breakdown: z.record(z.string(), z.number().int().min(0)),
  }),
});
