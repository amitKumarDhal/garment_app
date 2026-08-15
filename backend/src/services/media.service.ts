import { cloudinary } from '../config/cloudinary.config';
import { envConfig } from '../config/env.config';
import { ApiError } from '../utils/apiError';

export class MediaService {
  async generateUploadSignature(folder = 'yoobbel_mockups') {
    const timestamp = Math.round(new Date().getTime() / 1000);
    const paramsToSign = {
      timestamp,
      folder,
      upload_preset: envConfig.cloudinary.uploadPreset,
    };

    const signature = cloudinary.utils.api_sign_request(
      paramsToSign,
      envConfig.cloudinary.apiSecret
    );

    return {
      signature,
      timestamp,
      cloudName: envConfig.cloudinary.cloudName,
      apiKey: envConfig.cloudinary.apiKey,
      uploadPreset: envConfig.cloudinary.uploadPreset,
      folder,
    };
  }

  async uploadDirect(base64OrPath: string, folder = 'yoobbel_mockups') {
    try {
      const result = await cloudinary.uploader.upload(base64OrPath, {
        folder,
        upload_preset: envConfig.cloudinary.uploadPreset,
      });

      return {
        url: result.secure_url,
        publicId: result.public_id,
        format: result.format,
        bytes: result.bytes,
      };
    } catch (error: any) {
      throw ApiError.internal(`Cloudinary upload failed: ${error?.message || 'Unknown error'}`);
    }
  }
}
