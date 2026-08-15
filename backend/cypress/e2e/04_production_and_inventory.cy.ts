describe('04 - Production Floor & Inventory Pipeline E2E', () => {
  let payloads: any;

  before(() => {
    cy.fixture('test_payloads.json').then((data) => {
      payloads = data;
    });
  });

  describe('Production Floor Stage Enforcements', () => {
    it('POST /api/v1/production/cutting should block unauthenticated access', () => {
      cy.apiPost('/production/cutting', payloads.sampleCuttingEntry).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/production/printing should block unauthenticated access', () => {
      cy.apiPost('/production/printing', payloads.samplePrintingEntry).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/production/stitching should block unauthenticated access', () => {
      cy.apiPost('/production/stitching', payloads.sampleStitchingEntry).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/production/packing should block unauthenticated access', () => {
      cy.apiPost('/production/packing', payloads.samplePackingEntry).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('GET /api/v1/production/activities should block unauthenticated access', () => {
      cy.apiGet('/production/activities').then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });

  describe('Inventory Management & Transactions', () => {
    it('GET /api/v1/inventory should block unauthenticated access with 401', () => {
      cy.apiGet('/inventory').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('GET /api/v1/inventory/transactions should block unauthenticated access with 401', () => {
      cy.apiGet('/inventory/transactions').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/inventory/transactions should block unauthenticated stock adjustments with 401', () => {
      cy.apiPost('/inventory/transactions', payloads.sampleInventoryTx).then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });
});
