import { FastifyInstance } from 'fastify';
import { AssetService } from '../../services/AssetService';
import { SubmitAssetSchema } from '../../types/asset.dto';

export default async function (fastify: FastifyInstance) {
  const assetService = new AssetService();

  fastify.post('/assets', async (request, reply) => {
    try {
      const validatedData = SubmitAssetSchema.parse(request.body);
      const asset = await assetService.submitAsset(validatedData);
      reply.code(201).send({
        success: true,
        data: asset,
        metadata: {
          timestamp: new Date().toISOString(),
          request_id: request.id,
          version: 'v1',
        },
      });
    } catch (error) {
      reply.code(400).send({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input data',
          details: error.errors,
        },
      });
    }
  });
}
