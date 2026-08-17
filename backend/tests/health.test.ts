import { createApp } from '../src/app';
import http from 'http';

describe('GET /health', () => {
  let server: http.Server;
  let baseUrl: string;

  beforeAll((done) => {
    const app = createApp();
    server = app.listen(0, () => {
      const address = server.address();
      if (address && typeof address === 'object') {
        baseUrl = `http://localhost:${address.port}`;
      }
      done();
    });
  });

  afterAll((done) => {
    server.close(done);
  });

  it('should return 200 and success response', async () => {
    const res = await fetch(`${baseUrl}/health`);
    expect(res.status).toBe(200);

    const body = (await res.json()) as { success: boolean; message: string; timestamp: string };
    expect(body.success).toBe(true);
    expect(body.message).toBe('API is running');
    expect(body.timestamp).toBeDefined();
  });
});
