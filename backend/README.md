# YOOBBEL PRODUCTION ERP — FRESH BACKEND API

Enterprise Node.js / Express / TypeScript REST API service for Yoobbel Production ERP, backed by Supabase PostgreSQL and Cloudinary.

## Architecture

```
Client (Flutter App / GetX)
   ↓ (REST API via Authorization: Bearer <Supabase_JWT>)
Node.js Express TypeScript API Layer
   ↓ (Repository & Service Pattern)
Supabase PostgreSQL DB (Public Schema + Row Level Security) & Cloudinary
```

## Setup & Running Locally

1. **Install Dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Configure Environment Variables:**
   Copy `.env.example` to `.env` and fill in your Supabase project credentials & Cloudinary keys:
   ```bash
   cp .env.example .env
   ```

3. **Run PostgreSQL Database Migrations:**
   Copy and execute the SQL scripts in Supabase SQL Editor (or via Supabase CLI):
   - `database/migrations/001_initial_schema.sql`
   - `database/migrations/002_rls_policies.sql`

4. **Seed System Initial Administrator:**
   ```bash
   npm run seed
   ```

5. **Start Development Server:**
   ```bash
   npm run dev
   ```

6. **Run Automated Tests:**
   ```bash
   npm test
   ```

## Endpoints Overview (`/api/v1`)

- `/auth` - Registration (Pending Admin Approval), Login (Returns Supabase JWT), Profile
- `/users` - Workforce directory, pending approvals, admin approval gates
- `/clients` - Client master management
- `/products` - Product catalog & SKU management
- `/quotations` - Quotation creation (`ZBR26xxx` auto-serial) & math validation
- `/orders` - Order management (`ZBRxxx` transaction auto-serial), approvals, edit gates, deletion requests
- `/payments` - Advance payment request approvals
- `/inventory` - Fabric stock balances & audit logs (`IN` / `OUT` / `ADJUSTMENT`)
- `/production` - 5-stage factory tracking (`cutting`, `printing`, `stitching`, `packing`), live activity feed
- `/notifications` - In-app notification queue & unread badge count
- `/analytics` - Executive dashboard metrics & sales agent leaderboard
- `/media` - Signed upload signatures & Cloudinary media integration
