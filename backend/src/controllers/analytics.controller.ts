import { Request, Response, NextFunction } from 'express';
import { AnalyticsService } from '../services/analytics.service';
import { ApiResponse } from '../utils/apiResponse';

export class AnalyticsController {
  private analyticsService = new AnalyticsService();

  getDashboard = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { startDate, endDate } = req.query;
      const metrics = await this.analyticsService.getDashboardAnalytics(
        startDate as string,
        endDate as string
      );
      return ApiResponse.success(res, metrics);
    } catch (err) {
      next(err);
    }
  };

  getLeaderboard = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { startDate, endDate } = req.query;
      const leaderboard = await this.analyticsService.getLeaderboard(
        startDate as string,
        endDate as string
      );
      return ApiResponse.success(res, leaderboard);
    } catch (err) {
      next(err);
    }
  };
}
