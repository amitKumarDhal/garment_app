import { Request, Response, NextFunction } from 'express';
import { UserService } from '../services/user.service';
import { ApiResponse } from '../utils/apiResponse';

export class UserController {
  private userService = new UserService();

  getPending = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const list = await this.userService.getPendingUsers();
      return ApiResponse.success(res, list);
    } catch (err) {
      next(err);
    }
  };

  approve = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const result = await this.userService.approveUser(id, req.body);
      return ApiResponse.success(res, result, 'User status updated successfully');
    } catch (err) {
      next(err);
    }
  };

  remove = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      await this.userService.removeUser(id);
      return ApiResponse.success(res, null, 'User removed successfully');
    } catch (err) {
      next(err);
    }
  };
}
