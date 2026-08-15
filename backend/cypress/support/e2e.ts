import './commands';

// Prevent uncaught exception failures for non-fatal application errors
Cypress.on('uncaught:exception', (err, runnable) => {
  return false;
});
