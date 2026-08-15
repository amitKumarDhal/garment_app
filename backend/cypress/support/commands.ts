/// <reference types="cypress" />

declare namespace Cypress {
  interface Chainable {
    apiGet(endpoint: string, token?: string): Chainable<Cypress.Response<any>>;
    apiPost(endpoint: string, body: any, token?: string): Chainable<Cypress.Response<any>>;
    apiPut(endpoint: string, body: any, token?: string): Chainable<Cypress.Response<any>>;
    apiDelete(endpoint: string, token?: string): Chainable<Cypress.Response<any>>;
  }
}

/**
 * Normalizes API endpoint paths relative to the server baseUrl.
 * If endpoint starts with /api/v1, /api/health, or /, preserves it as is.
 * Otherwise prefixes with /api/v1.
 */
const formatUrl = (endpoint: string): string => {
  if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
    return endpoint;
  }
  if (endpoint.startsWith('/api/v1')) {
    return endpoint;
  }
  if (endpoint === '/' || endpoint.startsWith('/api/health')) {
    return endpoint;
  }
  const cleanPath = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  return `/api/v1${cleanPath}`;
};

Cypress.Commands.add('apiGet', (endpoint: string, token?: string) => {
  const headers: Record<string, string> = {
    'Accept': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return cy.request({
    method: 'GET',
    url: formatUrl(endpoint),
    headers,
    failOnStatusCode: false,
  });
});

Cypress.Commands.add('apiPost', (endpoint: string, body: any, token?: string) => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return cy.request({
    method: 'POST',
    url: formatUrl(endpoint),
    body,
    headers,
    failOnStatusCode: false,
  });
});

Cypress.Commands.add('apiPut', (endpoint: string, body: any, token?: string) => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return cy.request({
    method: 'PUT',
    url: formatUrl(endpoint),
    body,
    headers,
    failOnStatusCode: false,
  });
});

Cypress.Commands.add('apiDelete', (endpoint: string, token?: string) => {
  const headers: Record<string, string> = {
    'Accept': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return cy.request({
    method: 'DELETE',
    url: formatUrl(endpoint),
    headers,
    failOnStatusCode: false,
  });
});
