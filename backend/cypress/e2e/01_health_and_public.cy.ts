describe('01 - Health Check & Public Service Verification', () => {
  it('GET /api/v1/health should return HTTP 200 with service metadata', () => {
    cy.apiGet('/api/v1/health').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body).to.have.property('status', 'OK');
      expect(response.body).to.have.property('service', 'Zobra Production ERP API');
      expect(response.body).to.have.property('version', 'v1.0.0');
      expect(response.body).to.have.property('timestamp');
      
      // Verify timestamp is a valid recent ISO date string
      const date = new Date(response.body.timestamp);
      expect(isNaN(date.getTime())).to.be.false;
    });
  });

  it('GET /api/health root healthcheck should return HTTP 200 healthy status', () => {
    cy.apiGet('/api/health').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body).to.deep.eq({
        status: 'healthy',
        service: 'Zobra Production ERP API',
      });
    });
  });

  it('Security headers (Helmet) should be present on API responses', () => {
    cy.apiGet('/api/v1/health').then((response) => {
      expect(response.headers).to.have.property('x-content-type-options', 'nosniff');
      expect(response.headers).to.have.property('x-frame-options');
      expect(response.headers).to.have.property('cross-origin-resource-policy', 'same-origin');
      expect(response.headers).to.have.property('x-download-options', 'noopen');
    });
  });
});
