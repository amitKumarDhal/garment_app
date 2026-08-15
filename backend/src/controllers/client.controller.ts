import { Request, Response, NextFunction } from 'express';
import { ClientService } from '../services/client.service';
import { ApiResponse } from '../utils/apiResponse';

export class ClientController {
  private clientService = new ClientService();

  getAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const clients = await this.clientService.getClients();
      return ApiResponse.success(res, clients);
    } catch (err) {
      next(err);
    }
  };

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const client = await this.clientService.createClient(req.body, req.user!.id);
      return ApiResponse.created(res, client, 'Client created successfully');
    } catch (err) {
      next(err);
    }
  };
}
