import request from 'supertest';
import app from '../src/app';

describe('Zobra API Health Check Endpoint', () => {
  it('GET /api/v1/health should return 200 OK with service metadata', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('OK');
    expect(res.body.service).toBe('Zobra Production ERP API');
    expect(res.body.version).toBe('v1.0.0');
    expect(res.body.timestamp).toBeDefined();
  });
});
