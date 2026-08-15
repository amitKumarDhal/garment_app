import { Request, Response, NextFunction } from 'express';
import { ProductionService } from '../services/production.service';
import { ApiResponse } from '../utils/apiResponse';

export class ProductionController {
  private productionService = new ProductionService();

  cutting = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await this.productionService.logCutting(req.body, req.user!.name);
      return ApiResponse.created(res, entry, 'Cutting entry recorded & stock deducted successfully');
    } catch (err) {
      next(err);
    }
  };

  printing = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await this.productionService.logPrinting(req.body, req.user!.name);
      return ApiResponse.created(res, entry, 'Printing entry recorded successfully');
    } catch (err) {
      next(err);
    }
  };

  stitching = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await this.productionService.logStitching(req.body);
      return ApiResponse.created(res, entry, 'Stitching entry recorded successfully');
    } catch (err) {
      next(err);
    }
  };

  packing = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await this.productionService.logPacking(req.body);
      return ApiResponse.created(res, entry, 'Packing entry recorded successfully');
    } catch (err) {
      next(err);
    }
  };

  activities = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const logs = await this.productionService.getRecentActivities();
      return ApiResponse.success(res, logs);
    } catch (err) {
      next(err);
    }
  };
}
