import { NotificationRepository } from '../repositories/notification.repository';

export class NotificationService {
  private notificationRepo = new NotificationRepository();

  async getUserNotifications(userId: string) {
    const list = await this.notificationRepo.findByUserId(userId);
    const unreadCount = await this.notificationRepo.getUnreadCount(userId);
    return { notifications: list, unreadCount };
  }

  async markNotificationAsRead(id: string, userId: string) {
    return this.notificationRepo.markAsRead(id, userId);
  }
}
