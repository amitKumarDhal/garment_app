import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email address'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
    employeeId: z.string().optional(),
    role: z.enum(['SALES_MANAGER', 'SALES_ASSOCIATE', 'UNIT_SUPERVISOR']),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const userApprovalSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid user ID'),
  }),
  body: z.object({
    adminApproved: z.boolean().optional(),
    assignedSupervisorId: z.string().uuid().optional(),
  }),
});
