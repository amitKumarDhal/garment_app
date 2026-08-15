-- =============================================================================
-- YOOBBEL PRODUCTION ERP — SUPABASE ROW LEVEL SECURITY (RLS) POLICIES (002)
-- High-Security Data Protection Infrastructure
-- =============================================================================

-- Enable Row Level Security on all public tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stage_histories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.printing_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stitching_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.finishing_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packing_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- RLS POLICIES
-- -----------------------------------------------------------------------------

-- Service Role (Backend Node.js API using SUPABASE_SERVICE_ROLE_KEY) has Full Bypass Access
-- Public Client Users have fine-grained read/write policies below:

-- 1. USERS TABLE
CREATE POLICY "Users can read own profile or Admins can read all" ON public.users
    FOR SELECT USING (
        auth.uid() = id OR 
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'ADMIN')
    );

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- 2. ORDERS TABLE
CREATE POLICY "Sales Agents see own orders, Managers and Admins see all" ON public.orders
    FOR SELECT USING (
        marketing_person_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('ADMIN', 'SALES_MANAGER', 'UNIT_SUPERVISOR'))
    );

-- 3. NOTIFICATIONS TABLE
CREATE POLICY "Users can view and update own notifications" ON public.notifications
    FOR ALL USING (target_user_id = auth.uid());

-- 4. INVENTORY & PRODUCTION TABLES (Readable by staff, modified by supervisor/admin/service-role)
CREATE POLICY "Staff can view inventory" ON public.inventory_items
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Staff can view activities" ON public.activities
    FOR SELECT USING (auth.role() = 'authenticated');
