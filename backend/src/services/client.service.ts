import { ClientRepository } from '../repositories/client.repository';

export class ClientService {
  private clientRepo = new ClientRepository();

  async getClients() {
    return this.clientRepo.findAll();
  }

  async createClient(data: any, userId: string) {
    return this.clientRepo.create({
      ...data,
      created_by_id: userId,
    });
  }
}
