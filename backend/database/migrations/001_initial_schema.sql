-- =============================================================================
-- YOOBBEL PRODUCTION ERP — SUPABASE POSTGRESQL SCHEMA MIGRATION (001)
-- Clean Slate Relational Database Blueprint
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. ENUM TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE user_role AS ENUM (
    'ADMIN',
    'SALES_MANAGER',
    'SALES_ASSOCIATE',
    'UNIT_SUPERVISOR'
);

CREATE TYPE agent_rank AS ENUM (
    'JSA',
    'SSA',
    'SC',
    'SM'
);

CREATE TYPE user_status AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED'
);

CREATE TYPE order_status AS ENUM (
    'Placed',
    'Pending',
    'Approved',
    'Fab Purchased',
    'Fab Ready',
    'Cutting',
    'Cutting Done',
    'Printing',
    'Printed',
    'Stitching',
    'Stitched',
    'Finishing',
    'Packing',
    'Packed',
    'Out SRC',
    'Shipping',
    'Shipped',
    'Delivered',
    'Completed',
    'Rejected',
    'Cancelled',
    'Deleted'
);

CREATE TYPE payment_request_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);

CREATE TYPE inventory_action AS ENUM (
    'IN',
    'OUT',
    'ADJUSTMENT'
);

-- -----------------------------------------------------------------------------
-- 2. SEQUENCES FOR SERIAL NUMBERS
-- -----------------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS order_serial_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS quotation_serial_seq START WITH 1 INCREMENT BY 1;

-- Helper function to generate clean order serial (ZBR001, ZBR002, ...)
CREATE OR REPLACE FUNCTION generate_order_number() RETURNS VARCHAR(20) AS $$
DECLARE
    next_val INT;
BEGIN
    SELECT nextval('order_serial_seq') INTO next_val;
    RETURN 'ZBR' || LPAD(next_val::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql;

-- Helper function to generate clean quotation serial (ZBR26001, ...)
CREATE OR REPLACE FUNCTION generate_quotation_number() RETURNS VARCHAR(20) AS $$
DECLARE
    next_val INT;
    year_code VARCHAR(2);
BEGIN
    SELECT TO_CHAR(CURRENT_DATE, 'YY') INTO year_code;
    SELECT nextval('quotation_serial_seq') INTO next_val;
    RETURN 'ZBR' || year_code || LPAD(next_val::TEXT, 3, '0');
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 3. CORE PUBLIC TABLES
-- -----------------------------------------------------------------------------

-- 3.1 PUBLIC USERS (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    employee_id VARCHAR(50),
    role user_role NOT NULL DEFAULT 'SALES_ASSOCIATE',
    agent_rank agent_rank DEFAULT 'JSA',
    status user_status NOT NULL DEFAULT 'PENDING',
    admin_approved BOOLEAN DEFAULT FALSE,
    assigned_supervisor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 CLIENTS
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    organization VARCHAR(255),
    address TEXT,
    gst_number VARCHAR(50),
    pincode VARCHAR(10),
    state VARCHAR(100),
    created_by_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.3 PRODUCTS
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    product_type VARCHAR(100),
    fabric_type VARCHAR(100),
    neck_type VARCHAR(100),
    color VARCHAR(100),
    unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    gst_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.4 QUOTATIONS & ITEMS
CREATE TABLE IF NOT EXISTS public.quotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quotation_no VARCHAR(50) NOT NULL UNIQUE DEFAULT generate_quotation_number(),
    client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    client_name VARCHAR(255) NOT NULL,
    client_address TEXT,
    client_gst VARCHAR(50),
    sub_total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_gst NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    shipping NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    grand_total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'Draft',
    created_by_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.quotation_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quotation_id UUID NOT NULL REFERENCES public.quotations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    quantity INT NOT NULL DEFAULT 1,
    gst_percent NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    item_total NUMERIC(12, 2) NOT NULL DEFAULT 0.00
);

-- 3.5 ORDERS & ITEMS
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manual_order_no VARCHAR(50) NOT NULL UNIQUE DEFAULT generate_order_number(),
    client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    client_name VARCHAR(255) NOT NULL,
    client_phone VARCHAR(50),
    organization VARCHAR(255),
    client_address TEXT,
    client_gst_number VARCHAR(50),
    pincode VARCHAR(10),
    state VARCHAR(100),
    product_code VARCHAR(100),
    product_name VARCHAR(255) NOT NULL,
    product_details TEXT,
    quantity INT NOT NULL DEFAULT 1,
    priority VARCHAR(50) NOT NULL DEFAULT 'Medium',
    status order_status NOT NULL DEFAULT 'Pending',
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    gst_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    shipping_charge NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    advance_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    balance_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    effective_revenue NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    marketing_person_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    marketing_person_name VARCHAR(255) NOT NULL,
    mockup_url TEXT,
    is_delete_requested BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    order_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivery_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_updated_by VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_code VARCHAR(100),
    product_name VARCHAR(255) NOT NULL,
    size_description VARCHAR(255),
    qty INT NOT NULL DEFAULT 1,
    price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    gst_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    neck_type VARCHAR(100) DEFAULT 'Not Specified',
    product_type VARCHAR(100) DEFAULT 'Not Specified',
    color VARCHAR(100) DEFAULT 'Not Specified',
    fabric_type VARCHAR(100) DEFAULT 'Not Specified'
);

-- 3.6 PAYMENT REQUESTS & STAGE HISTORIES
CREATE TABLE IF NOT EXISTS public.payment_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    manual_order_no VARCHAR(50) NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    agent_name VARCHAR(255) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    status payment_request_status NOT NULL DEFAULT 'pending',
    is_edit_request BOOLEAN NOT NULL DEFAULT FALSE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    approved_by_id UUID REFERENCES public.users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.stage_histories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    stage order_status NOT NULL,
    updated_by VARCHAR(255) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.7 INVENTORY & LOGS
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    fabric_type VARCHAR(100) NOT NULL,
    color VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'KG',
    quantity NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_fabric_color UNIQUE(fabric_type, color)
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    fabric_type VARCHAR(100) NOT NULL,
    color VARCHAR(100) NOT NULL,
    action inventory_action NOT NULL,
    quantity NUMERIC(12, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'KG',
    added_by VARCHAR(255) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.8 PRODUCTION STAGE ENTRIES
CREATE TABLE IF NOT EXISTS public.cutting_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    style_no VARCHAR(100) NOT NULL,
    lot_no VARCHAR(100) NOT NULL,
    fabric_type VARCHAR(100) NOT NULL,
    consumption NUMERIC(8, 2) NOT NULL,
    total_fabric_used NUMERIC(12, 2) NOT NULL,
    sizes JSONB NOT NULL DEFAULT '{}'::jsonb,
    total_quantity INT NOT NULL,
    entry_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(50) NOT NULL DEFAULT 'Cut Completed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.printing_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    style_no VARCHAR(100) NOT NULL,
    received_from_cutting INT NOT NULL,
    damaged_quantities JSONB NOT NULL DEFAULT '{}'::jsonb,
    total_damaged INT NOT NULL DEFAULT 0,
    net_good_pieces INT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Printing Completed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.stitching_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    operator VARCHAR(255) NOT NULL,
    style_no VARCHAR(100) NOT NULL,
    operation_type VARCHAR(100) NOT NULL,
    assigned_qty INT NOT NULL,
    completed_qty INT NOT NULL,
    rejected_qty INT NOT NULL DEFAULT 0,
    efficiency NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'Stitching Record Added',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.finishing_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    checker_name VARCHAR(255) NOT NULL,
    style_no VARCHAR(100) NOT NULL,
    received_qty INT NOT NULL,
    ironed_qty INT NOT NULL,
    packed_qty INT NOT NULL,
    defective_qty INT NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'Ready for Shipment',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.packing_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    carton_no VARCHAR(100) NOT NULL,
    style_no VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'M',
    total_pieces INT NOT NULL,
    breakdown JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(50) NOT NULL DEFAULT 'Packed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.shipments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    courier_partner VARCHAR(255) NOT NULL,
    tracking_number VARCHAR(255) NOT NULL,
    shipped_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dispatched_by VARCHAR(255) NOT NULL
);

-- 3.9 NOTIFICATIONS & LIVE ACTIVITIES
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255) NOT NULL,
    time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    icon_code INT NOT NULL,
    color_value INT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(100) NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4. PERFORMANCE INDEXES
-- -----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_marketing ON public.orders(marketing_person_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_target ON public.notifications(target_user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_inventory_lookup ON public.inventory_items(fabric_type, color);
CREATE INDEX IF NOT EXISTS idx_cutting_style ON public.cutting_entries(style_no);
