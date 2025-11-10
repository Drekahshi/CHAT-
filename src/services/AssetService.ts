import { PrismaClient } from '@prisma/client';
import { SubmitAssetDTO } from '../types/asset.dto';

const prisma = new PrismaClient();

export class AssetService {
  async submitAsset(data: SubmitAssetDTO) {
    const asset = await prisma.asset.create({
      data: {
        ...data,
        status: 'submitted',
      },
    });
    return asset;
  }
}
