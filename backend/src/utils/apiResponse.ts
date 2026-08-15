import { Response } from 'express';

export class ApiResponse {
  static success(res: Response, data: any = null, message = 'Success', statusCode = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  static created(res: Response, data: any = null, message = 'Resource created successfully') {
    return res.status(201).json({
      success: true,
      message,
      data,
    });
  }

  static error(res: Response, message = 'Error', statusCode = 500, errors: any[] = []) {
    return res.status(statusCode).json({
      success: false,
      message,
      errors,
    });
  }
}
