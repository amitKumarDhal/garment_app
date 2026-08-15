import { Request, Response, NextFunction } from 'express';
import { InventoryService } from '../services/inventory.service';
import { ApiResponse } from '../utils/apiResponse';

export class InventoryController {
  private inventoryService = new InventoryService();

  getItems = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const items = await this.inventoryService.getInventoryItems();
      return ApiResponse.success(res, items);
    } catch (err) {
      next(err);
    }
  };

  getTransactions = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const logs = await this.inventoryService.getInventoryTransactions();
      return ApiResponse.success(res, logs);
    } catch (err) {
      next(err);
    }
  };

  recordTransaction = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const log = await this.inventoryService.recordTransaction(req.body, req.user!.name);
      return ApiResponse.created(res, log, 'Inventory transaction recorded successfully');
    } catch (err) {
      next(err);
    }
  };
}
