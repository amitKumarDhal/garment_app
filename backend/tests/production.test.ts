import request from 'supertest';
import app from '../src/app';

describe('Production Stage API Tests', () => {
  it('POST /api/v1/production/cutting should block unauthenticated access', async () => {
    const res = await request(app).post('/api/v1/production/cutting').send({
      styleNo: 'STYLE-001',
      lotNo: 'LOT-01',
      fabricType: 'Dotknit',
      consumption: 1.5,
      sizes: { S: 10, M: 20 },
      totalQuantity: 30,
    });
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/production/printing should block unauthenticated access', async () => {
    const res = await request(app).post('/api/v1/production/printing').send({
      styleNo: 'STYLE-001',
      receivedFromCutting: 100,
      damagedQuantities: { screen_damage: 3, ink_bleed: 2 },
    });
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/production/stitching should block unauthenticated access', async () => {
    const res = await request(app).post('/api/v1/production/stitching').send({
      operator: 'Operator A',
      styleNo: 'STYLE-001',
      operationType: 'Full Assembly',
      assignedQty: 50,
      completedQty: 48,
      rejectedQty: 2,
    });
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/production/packing should block unauthenticated access', async () => {
    const res = await request(app).post('/api/v1/production/packing').send({
      cartonNo: 'CTN-001',
      styleNo: 'STYLE-001',
      category: 'M',
      totalPieces: 120,
      breakdown: { S: 30, M: 40, L: 30, XL: 20 },
    });
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/production/activities should block unauthenticated access', async () => {
    const res = await request(app).get('/api/v1/production/activities');
    expect(res.status).toBe(401);
  });
});
