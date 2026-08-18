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

  getLastSerial = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const serialData = await this.orderService.getLastSerial();
      return ApiResponse.success(res, serialData, 'Latest order serial fetched successfully');
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

  update = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const order = await this.orderService.updateOrder(req.params.id, req.body, req.user!);
      return ApiResponse.success(res, order, 'Order updated successfully');
    } catch (err) {
      next(err);
    }
  };

  updateStatus = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { status, ...extra } = req.body;
      const order = await this.orderService.updateOrderStatus(req.params.id, status, req.user!, extra);
      return ApiResponse.success(res, order, 'Order status updated successfully');
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

  delete = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await this.orderService.deleteOrder(req.params.id, req.user!);
      return ApiResponse.success(res, result, 'Order deleted successfully');
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
