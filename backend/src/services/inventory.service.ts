import { InventoryRepository } from '../repositories/inventory.repository';

export class InventoryService {
  private inventoryRepo = new InventoryRepository();

  async getInventoryItems() {
    return this.inventoryRepo.findAllItems();
  }

  async getInventoryTransactions() {
    return this.inventoryRepo.findAllTransactions();
  }

  async recordTransaction(data: {
    fabricType: string;
    color: string;
    action: 'IN' | 'OUT' | 'ADJUSTMENT';
    quantity: number;
    unit?: string;
  }, userName: string) {
    return this.inventoryRepo.recordTransaction(
      data.fabricType,
      data.color,
      data.action,
      data.quantity,
      userName,
      data.unit
    );
  }
}
