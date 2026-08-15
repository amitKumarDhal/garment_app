import request from 'supertest';
import app from '../src/app';

describe('Inventory Stock API Tests', () => {
  it('GET /api/v1/inventory should require authentication', async () => {
    const res = await request(app).get('/api/v1/inventory');
    expect(res.status).toBe(401);
  });
});
