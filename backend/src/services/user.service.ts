import { UserRepository } from '../repositories/user.repository';
import { ApiError } from '../utils/apiError';

export class UserService {
  private userRepo = new UserRepository();

  async getPendingUsers() {
    return this.userRepo.findPending();
  }

  async approveUser(id: string, updates: {
    adminApproved?: boolean;
    assignedSupervisorId?: string;
  }) {
    const user = await this.userRepo.findById(id);
    if (!user) throw ApiError.notFound('User not found');

    const updatePayload: Record<string, any> = {};

    if (updates.adminApproved !== undefined) {
      updatePayload.admin_approved = updates.adminApproved;
      if (updates.adminApproved) {
        updatePayload.status = 'APPROVED';
      }
    }

    if (updates.assignedSupervisorId !== undefined) {
      updatePayload.assigned_supervisor_id = updates.assignedSupervisorId;
    }

    return this.userRepo.updateApproval(id, updatePayload);
  }

  async removeUser(id: string) {
    return this.userRepo.deleteUser(id);
  }
}
