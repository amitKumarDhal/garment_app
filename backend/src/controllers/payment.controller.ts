import { Request, Response, NextFunction } from 'express';
import { PaymentService } from '../services/payment.service';
import { ApiResponse } from '../utils/apiResponse';

export class PaymentController {
  private paymentService = new PaymentService();

  getPending = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const list = await this.paymentService.getPendingPayments();
      return ApiResponse.success(res, list);
    } catch (err) {
      next(err);
    }
  };

  approve = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.paymentService.approvePayment(req.params.id, req.user!);
      return ApiResponse.success(res, result, 'Payment approved');
    } catch (err) {
      next(err);
    }
  };

  reject = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.paymentService.rejectPayment(req.params.id, req.user!);
      return ApiResponse.success(res, result, 'Payment rejected');
    } catch (err) {
      next(err);
    }
  };
}
