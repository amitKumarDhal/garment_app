import request from 'supertest';
import app from '../src/app';

describe('Authentication API Endpoint Tests', () => {
  it('POST /api/v1/auth/register should fail validation if required fields are missing', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({});
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Validation failed');
  });

  it('POST /api/v1/auth/login should fail validation on invalid payload', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({ email: 'invalid-email' });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('GET /api/v1/auth/me should reject unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.message).toContain('Access token is missing');
  });

  it('POST /api/v1/auth/register should REJECT WORKER role', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      name: 'Test Worker',
      email: 'worker@yoobbel.com',
      password: 'Test1234!',
      role: 'WORKER',
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Validation failed');
  });

  it('POST /api/v1/auth/register should REJECT SHIFT_SUPERVISOR role', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      name: 'Test Shift Sup',
      email: 'shift@yoobbel.com',
      password: 'Test1234!',
      role: 'SHIFT_SUPERVISOR',
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Validation failed');
  });

  it('POST /api/v1/auth/register should REJECT ADMIN role via public registration', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      name: 'Test Admin',
      email: 'admin@yoobbel.com',
      password: 'Test1234!',
      role: 'ADMIN',
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Validation failed');
  });
});
