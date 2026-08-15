import { ProductionRepository } from '../repositories/production.repository';

export class ProductionService {
  private productionRepo = new ProductionRepository();

  async logCutting(data: any, userName: string) {
    return this.productionRepo.logCutting({ ...data, addedBy: userName });
  }

  async logPrinting(data: any, userName: string) {
    return this.productionRepo.logPrinting({ ...data, addedBy: userName });
  }

  async logStitching(data: any) {
    return this.productionRepo.logStitching(data);
  }

  async logPacking(data: any) {
    return this.productionRepo.logPacking(data);
  }

  async getRecentActivities() {
    return this.productionRepo.findRecentActivities();
  }
}
