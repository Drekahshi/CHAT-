import { z } from 'zod';

export const SubmitAssetSchema = z.object({
  creatorId: z.string().uuid(),
  title: z.string().min(3).max(255),
  description: z.string().max(5000).optional(),
  assetType: z.enum(['art', 'music', 'craft', 'story', 'ritual']),
  ipfsHash: z.string().startsWith('Qm'),
  metadataUri: z.string().url(),
  accessLevel: z.enum(['public', 'restricted', 'sacred']),
  genderSpecificAccess: z.string().optional(),
  attributes: z.record(z.string(), z.any()).optional(),
  language: z.string().min(2).max(10).optional(),
  region: z.string().min(2).max(100).optional(),
});

export type SubmitAssetDTO = z.infer<typeof SubmitAssetSchema>;
