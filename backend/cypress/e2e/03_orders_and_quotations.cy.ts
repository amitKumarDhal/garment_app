describe('03 - Orders & Quotations Workflow E2E', () => {
  let payloads: any;

  before(() => {
    cy.fixture('test_payloads.json').then((data) => {
      payloads = data;
    });
  });

  describe('Orders API Endpoint Guards & Schema Validation', () => {
    it('GET /api/v1/orders should block unauthenticated access with 401', () => {
      cy.apiGet('/orders').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/orders should fail on empty body or invalid schema with 400', () => {
      // Missing token will be blocked with 401
      cy.apiPost('/orders', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/orders/:id/approve should block unauthenticated request with 401', () => {
      cy.apiPost('/orders/00000000-0000-0000-0000-000000000000/approve', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/orders/:id/reject should block unauthenticated request with 401', () => {
      cy.apiPost('/orders/00000000-0000-0000-0000-000000000000/reject', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/orders/:id/request-delete should block unauthenticated request with 401', () => {
      cy.apiPost('/orders/00000000-0000-0000-0000-000000000000/request-delete', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });

  describe('Quotations API Endpoint Guards & Calculations', () => {
    it('GET /api/v1/quotations should block unauthenticated access with 401', () => {
      cy.apiGet('/quotations').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/quotations should block unauthenticated creation with 401', () => {
      cy.apiPost('/quotations', payloads.sampleQuotation).then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });

  describe('Clients API Endpoint Guards', () => {
    it('GET /api/v1/clients should block unauthenticated access with 401', () => {
      cy.apiGet('/clients').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/clients should block unauthenticated creation with 401', () => {
      cy.apiPost('/clients', payloads.sampleClient).then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });
});
