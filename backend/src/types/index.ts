export type UserRole = 
  | 'ADMIN'
  | 'SALES_MANAGER'
  | 'SALES_ASSOCIATE'
  | 'UNIT_SUPERVISOR';

export type AgentRank = 'JSA' | 'SSA' | 'SC' | 'SM';

export type UserStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export type OrderStatus =
  | 'Pending'
  | 'Approved'
  | 'Production'
  | 'Dispatched'
  | 'Delivered'
  | 'Placed'
  | 'Fab Purchased'
  | 'Fab Ready'
  | 'Cutting'
  | 'Cutting Done'
  | 'Printing'
  | 'Printed'
  | 'Stitching'
  | 'Stitched'
  | 'Finishing'
  | 'Packing'
  | 'Packed'
  | 'Out SRC'
  | 'Shipping'
  | 'Shipped'
  | 'Completed'
  | 'Rejected'
  | 'Cancelled'
  | 'Deleted';

export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
  agentRank: AgentRank;
  status: UserStatus;
  name: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}
