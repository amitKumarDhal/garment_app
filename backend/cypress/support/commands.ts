/// <reference types="cypress" />

declare namespace Cypress {
  interface Chainable {
    apiGet(endpoint: string, token?: string): Chainable<Cypress.Response<any>>;
    apiPost(endpoint: string, body: any, token?: string): Chainable<Cypress.Response<any>>;
    apiPut(endpoint: string, body: any, token?: string): Chainable<Cypress.Response<any>>;
    apiDelete(endpoint: string, token?: string): Chainable<Cypress.Response<any>>;
  }
}

Cypress.Commands.add('apiGet', (endpoint: string, token?: string) => {
  const headers: Record<string, string> = {
    'Accept': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return cy.request({
    method: 'GET',
    url: endpoint,
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
    url: endpoint,
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
    url: endpoint,
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
    url: endpoint,
    headers,
    failOnStatusCode: false,
  });
});
