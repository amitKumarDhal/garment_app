import { AnalyticsRepository } from '../repositories/analytics.repository';

export class AnalyticsService {
  private analyticsRepo = new AnalyticsRepository();

  async getDashboardAnalytics(startDate?: string, endDate?: string) {
    const start = startDate || new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
    const end = endDate || new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0, 23, 59, 59).toISOString();

    return this.analyticsRepo.getDashboardMetrics(start, end);
  }

  async getLeaderboard(startDate?: string, endDate?: string) {
    const start = startDate || new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
    const end = endDate || new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0, 23, 59, 59).toISOString();

    return this.analyticsRepo.getLeaderboardData(start, end);
  }
}
