describe('02 - Authentication & Security Pipeline E2E', () => {
  let payloads: any;

  before(() => {
    cy.fixture('test_payloads.json').then((data) => {
      payloads = data;
    });
  });

  describe('Validation & Payload Rejection Rules', () => {
    it('POST /api/v1/auth/register should fail on empty body with 400 Validation Error', () => {
      cy.apiPost('/auth/register', payloads.invalidAuth.empty).then((res) => {
        expect(res.status).to.eq(400);
        expect(res.body.success).to.be.false;
        expect(res.body.message).to.eq('Validation failed');
        expect(res.body.errors).to.be.an('array').that.is.not.empty;
      });
    });

    it('POST /api/v1/auth/register should fail on invalid email and short password', () => {
      cy.apiPost('/auth/register', {
        name: 'Invalid Test User',
        email: 'not-an-email',
        password: '123',
        role: 'SALES_ASSOCIATE',
      }).then((res) => {
        expect(res.status).to.eq(400);
        expect(res.body.success).to.be.false;
      });
    });

    it('POST /api/v1/auth/login should fail on malformed login body', () => {
      cy.apiPost('/auth/login', payloads.invalidAuth.badEmail).then((res) => {
        expect(res.status).to.eq(400);
        expect(res.body.success).to.be.false;
      });
    });
  });

  describe('Legacy Role Elimination & Prevention', () => {
    it('POST /api/v1/auth/register should strictly REJECT legacy WORKER role with 400', () => {
      cy.apiPost('/auth/register', payloads.legacyRoles.worker).then((res) => {
        expect(res.status).to.eq(400);
        expect(res.body.success).to.be.false;
        expect(res.body.message).to.eq('Validation failed');
      });
    });

    it('POST /api/v1/auth/register should strictly REJECT legacy SHIFT_SUPERVISOR role with 400', () => {
      cy.apiPost('/auth/register', payloads.legacyRoles.shiftSupervisor).then((res) => {
        expect(res.status).to.eq(400);
        expect(res.body.success).to.be.false;
        expect(res.body.message).to.eq('Validation failed');
      });
    });

    it('POST /api/v1/auth/register should strictly REJECT self-registration as ADMIN with 400', () => {
      cy.apiPost('/auth/register', payloads.legacyRoles.adminPublic).then((res) => {
        expect(res.status).to.eq(400);
        expect(res.body.success).to.be.false;
        expect(res.body.message).to.eq('Validation failed');
      });
    });
  });

  describe('JWT Bearer Authentication Enforcement', () => {
    it('GET /api/v1/auth/me should reject request when Authorization header is absent', () => {
      cy.apiGet('/auth/me').then((res) => {
        expect(res.status).to.eq(401);
        expect(res.body.success).to.be.false;
        expect(res.body.message).to.contain('Access token is missing');
      });
    });

    it('GET /api/v1/auth/me should reject request with malformed Authorization token', () => {
      cy.apiGet('/auth/me', 'invalid-token-format').then((res) => {
        expect(res.status).to.eq(401);
        expect(res.body.success).to.be.false;
      });
    });

    it('GET /api/v1/auth/me should reject request with forged JWT Bearer token', () => {
      const forgedJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkZvcmdlZCJ9.invalidSig';
      cy.apiGet('/auth/me', forgedJwt).then((res) => {
        expect(res.status).to.eq(401);
        expect(res.body.success).to.be.false;
      });
    });
  });
});
