import request from 'supertest';
import app from '../src/app';

describe('Order & Authorization API Security Tests', () => {
  it('GET /api/v1/orders should reject unauthorized request without Bearer token', async () => {
    const res = await request(app).get('/api/v1/orders');
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/orders should reject request with invalid token', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', 'Bearer invalid_token')
      .send({ clientName: 'Test' });
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/orders/:id/approve should reject unauthenticated request', async () => {
    const res = await request(app).post('/api/v1/orders/00000000-0000-0000-0000-000000000000/approve');
    expect(res.status).toBe(401);
  });
});
