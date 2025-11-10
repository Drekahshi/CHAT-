import Fastify from 'fastify';
import assetRoutes from './api/routes/assetRoutes';

const server = Fastify({
  logger: true,
});

server.register(assetRoutes, { prefix: '/api/v1' });

server.get('/health', async (request, reply) => {
  return { status: 'ok' };
});

const start = async () => {
  try {
    await server.listen({ port: 3000, host: '0.0.0.0' });
    server.log.info(`Server listening on port 3000`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
