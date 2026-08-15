import { Request, Response, NextFunction } from 'express';
import { ProductService } from '../services/product.service';
import { ApiResponse } from '../utils/apiResponse';

export class ProductController {
  private productService = new ProductService();

  getAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const products = await this.productService.getProducts();
      return ApiResponse.success(res, products);
    } catch (err) {
      next(err);
    }
  };

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const product = await this.productService.createProduct(req.body);
      return ApiResponse.created(res, product, 'Product created successfully');
    } catch (err) {
      next(err);
    }
  };
}
