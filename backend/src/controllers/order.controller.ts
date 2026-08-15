import { Request, Response, NextFunction } from 'express';
import { OrderService } from '../services/order.service';
import { ApiResponse } from '../utils/apiResponse';

export class OrderController {
  private orderService = new OrderService();

  getAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const statusFilter = req.query.status ? (req.query.status as string).split(',') : undefined;
      const orders = await this.orderService.getOrders(req.user!, statusFilter);
      return ApiResponse.success(res, orders);
    } catch (err) {
      next(err);
    }
  };

  getById = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const order = await this.orderService.getOrderById(req.params.id);
      return ApiResponse.success(res, order);
    } catch (err) {
      next(err);
    }
  };

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const order = await this.orderService.createOrder(req.body, req.user!);
      return ApiResponse.created(res, order, 'Order created successfully');
    } catch (err) {
      next(err);
    }
  };

  approve = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const order = await this.orderService.approveOrder(req.params.id, req.user!, req.body);
      return ApiResponse.success(res, order, 'Order approved successfully');
    } catch (err) {
      next(err);
    }
  };

  reject = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const order = await this.orderService.rejectOrder(req.params.id, req.user!);
      return ApiResponse.success(res, order, 'Order rejected successfully');
    } catch (err) {
      next(err);
    }
  };

  requestDelete = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const order = await this.orderService.requestDeletion(req.params.id, req.user!);
      return ApiResponse.success(res, order, 'Order deletion requested');
    } catch (err) {
      next(err);
    }
  };
}
