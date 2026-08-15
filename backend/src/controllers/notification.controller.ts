import { Request, Response, NextFunction } from 'express';
import { NotificationService } from '../services/notification.service';
import { ApiResponse } from '../utils/apiResponse';

export class NotificationController {
  private notificationService = new NotificationService();

  getUserNotifications = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data = await this.notificationService.getUserNotifications(req.user!.id);
      return ApiResponse.success(res, data);
    } catch (err) {
      next(err);
    }
  };

  markAsRead = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const updated = await this.notificationService.markNotificationAsRead(req.params.id, req.user!.id);
      return ApiResponse.success(res, updated, 'Notification marked as read');
    } catch (err) {
      next(err);
    }
  };
}
