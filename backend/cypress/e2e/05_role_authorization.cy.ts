describe('05 - Role-Based Access Control (RBAC) & Governance E2E', () => {
  describe('User Management Governance', () => {
    it('GET /api/v1/users/pending should block unauthenticated access with 401', () => {
      cy.apiGet('/users/pending').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/users/:id/approve should block unauthenticated access with 401', () => {
      cy.apiPost('/users/00000000-0000-0000-0000-000000000000/approve', { role: 'SALES_ASSOCIATE' }).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/users/:id/reject should block unauthenticated access with 401', () => {
      cy.apiPost('/users/00000000-0000-0000-0000-000000000000/reject', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });

  describe('Payment Approval Governance', () => {
    it('GET /api/v1/payments/pending should block unauthenticated access with 401', () => {
      cy.apiGet('/payments/pending').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/payments/:id/approve should block unauthenticated access with 401', () => {
      cy.apiPost('/payments/00000000-0000-0000-0000-000000000000/approve', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('POST /api/v1/payments/:id/reject should block unauthenticated access with 401', () => {
      cy.apiPost('/payments/00000000-0000-0000-0000-000000000000/reject', {}).then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });

  describe('Analytics & Media Endpoints', () => {
    it('GET /api/v1/analytics/dashboard should block unauthenticated access with 401', () => {
      cy.apiGet('/analytics/dashboard').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('GET /api/v1/analytics/leaderboard should block unauthenticated access with 401', () => {
      cy.apiGet('/analytics/leaderboard').then((res) => {
        expect(res.status).to.eq(401);
      });
    });

    it('GET /api/v1/media/signature should block unauthenticated access with 401', () => {
      cy.apiGet('/media/signature').then((res) => {
        expect(res.status).to.eq(401);
      });
    });
  });
});
