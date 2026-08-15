import { PaymentRepository } from '../repositories/payment.repository';
import { OrderRepository } from '../repositories/order.repository';
import { ApiError } from '../utils/apiError';
import { AuthUser } from '../types';

export class PaymentService {
  private paymentRepo = new PaymentRepository();
  private orderRepo = new OrderRepository();

  async getPendingPayments() {
    return this.paymentRepo.findAllPending();
  }

  async approvePayment(requestId: string, user: AuthUser) {
    const paymentReq = await this.paymentRepo.updateStatus(requestId, 'approved', user.id);
    if (paymentReq && paymentReq.order_id) {
      // Update order status to Approved
      await this.orderRepo.updateStatus(paymentReq.order_id, 'Approved', user.name);
    }
    return paymentReq;
  }

  async rejectPayment(requestId: string, user: AuthUser) {
    return this.paymentRepo.updateStatus(requestId, 'rejected', user.id);
  }
}
