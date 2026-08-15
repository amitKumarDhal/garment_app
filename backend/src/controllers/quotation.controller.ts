import { Request, Response, NextFunction } from 'express';
import { QuotationService } from '../services/quotation.service';
import { ApiResponse } from '../utils/apiResponse';

export class QuotationController {
  private quotationService = new QuotationService();

  getAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const quotes = await this.quotationService.getQuotations();
      return ApiResponse.success(res, quotes);
    } catch (err) {
      next(err);
    }
  };

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const quote = await this.quotationService.createQuotation(req.body, req.user!.id);
      return ApiResponse.created(res, quote, 'Quotation generated successfully');
    } catch (err) {
      next(err);
    }
  };
}
