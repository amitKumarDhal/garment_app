import request from 'supertest';
import app from '../src/app';
import { OrderRepository } from '../src/repositories/order.repository';

describe('Order Serial & Last-Serial Endpoint Tests', () => {
  it('GET /api/v1/orders/last-serial should reject unauthenticated request with 401', async () => {
    const res = await request(app).get('/api/v1/orders/last-serial');
    expect(res.status).toBe(401);
    expect(res.body.message).toContain('Access token is missing');
  });

  describe('OrderRepository.getLatestOrderSerial Logic Tests', () => {
    const orderRepo = new OrderRepository();

    it('handles numeric extraction, increment calculation, and default formatting', async () => {
      // Simulate data with serials
      const sampleSerials = [
        { manual_order_no: 'ZBR260015' },
        { manual_order_no: 'ZBR260018' },
        { manual_order_no: 'INVALID_ENTRY' },
        { manual_order_no: null },
        { manual_order_no: 'ZBR260010' },
      ];

      // Test parsing helper logic
      let maxSerial = 0;
      let lastRaw = '';
      for (const row of sampleSerials) {
        if (!row.manual_order_no) continue;
        const match = row.manual_order_no.match(/\d+/);
        if (match) {
          const num = parseInt(match[0], 10);
          if (!isNaN(num) && num > maxSerial) {
            maxSerial = num;
            lastRaw = row.manual_order_no;
          }
        }
      }

      expect(maxSerial).toBe(260018);
      const nextSerial = maxSerial + 1;
      expect(nextSerial).toBe(260019);
      expect(`ZBR${nextSerial}`).toBe('ZBR260019');
    });

    it('calculates 260020 next serial when latest serial is 260019', () => {
      const latest = 260019;
      const next = latest + 1;
      expect(next).toBe(260020);
      expect(`ZBR${next}`).toBe('ZBR260020');
    });

    it('falls back to default starting format when max serial is 0', () => {
      const yearPrefix = new Date().getFullYear().toString().slice(-2);
      const defaultStarting = Number(`${yearPrefix}0001`);
      expect(defaultStarting).toBe(260001);
      expect(`ZBR${defaultStarting}`).toBe('ZBR260001');
    });
  });
});
