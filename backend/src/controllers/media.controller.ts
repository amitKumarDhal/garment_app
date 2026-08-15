import { Request, Response, NextFunction } from 'express';
import { MediaService } from '../services/media.service';
import { ApiResponse } from '../utils/apiResponse';

export class MediaController {
  private mediaService = new MediaService();

  getSignSignature = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const folder = (req.query.folder as string) || 'yoobbel_mockups';
      const signatureData = await this.mediaService.generateUploadSignature(folder);
      return ApiResponse.success(res, signatureData, 'Upload signature generated successfully');
    } catch (err) {
      next(err);
    }
  };

  uploadDirect = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { file, folder } = req.body;
      const result = await this.mediaService.uploadDirect(file, folder);
      return ApiResponse.success(res, result, 'Image uploaded to Cloudinary successfully');
    } catch (err) {
      next(err);
    }
  };
}
