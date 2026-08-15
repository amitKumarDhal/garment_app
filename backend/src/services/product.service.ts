import { ProductRepository } from '../repositories/product.repository';

export class ProductService {
  private productRepo = new ProductRepository();

  async getProducts() {
    return this.productRepo.findAll();
  }

  async createProduct(data: any) {
    return this.productRepo.create(data);
  }
}
