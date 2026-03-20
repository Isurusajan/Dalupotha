-- ==============================================================================
-- Project Dalupotha - Database Schema (PostgreSQL)
-- ==============================================================================

-- Enable UUID extension (if using an older version of PostgreSQL, otherwise gen_random_uuid() is native in 13+)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. users
-- Core Authentication & Roles table
-- ------------------------------------------------------------------------------
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('SMALL_HOLDER', 'TA', 'MG', 'EXT', 'SK', 'ST', 'FT')),
    contact_number VARCHAR(15) UNIQUE,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'PENDING')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 2. small_holders
-- Supplier Profile (Extends users table)
-- ------------------------------------------------------------------------------
CREATE TABLE small_holders (
    supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    passbook_no VARCHAR(50) UNIQUE NOT NULL,
    address TEXT,
    land_name VARCHAR(100),
    gps_lat DECIMAL(10,8) NOT NULL,
    gps_long DECIMAL(11,8) NOT NULL,
    in_charge_no VARCHAR(50),
    arcs DECIMAL(10,2),
    otp_verified BOOLEAN DEFAULT FALSE
);

-- ------------------------------------------------------------------------------
-- 3. inventory
-- Stores: Fertilizer & Leaf Bags
-- ------------------------------------------------------------------------------
CREATE TABLE inventory (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_category VARCHAR(50) NOT NULL CHECK (item_category IN ('FERTILIZER', 'LEAF_BAG', 'MACHINERY')),
    item_name VARCHAR(100) NOT NULL,
    quantity_in_stock INTEGER DEFAULT 0,
    unit_cost DECIMAL(10,2) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 4. tri_circulars
-- Communication / Dashboards / Documents
-- ------------------------------------------------------------------------------
CREATE TABLE tri_circulars (
    circular_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content_url VARCHAR(255) NOT NULL,
    published_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    target_audience VARCHAR(50) DEFAULT 'ALL' CHECK (target_audience IN ('ALL', 'SMALL_HOLDERS', 'MANAGEMENT'))
);

-- ------------------------------------------------------------------------------
-- 5. leaf_collections
-- Brought Leaf Register (Daily green leaf collections)
-- ------------------------------------------------------------------------------
CREATE TABLE leaf_collections (
    collection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID REFERENCES small_holders(supplier_id) ON DELETE RESTRICT,
    transport_agent_id UUID REFERENCES users(user_id) ON DELETE RESTRICT,
    gross_weight DECIMAL(8,2) NOT NULL,
    water_deduction DECIMAL(8,2) DEFAULT 0.00,
    net_weight DECIMAL(8,2) NOT NULL,
    quality_grade VARCHAR(20),
    gps_lat DECIMAL(10,8) NOT NULL,
    gps_long DECIMAL(11,8) NOT NULL,
    collection_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'SYNCED' CHECK (sync_status IN ('PENDING_SYNC', 'SYNCED'))
);

-- ------------------------------------------------------------------------------
-- 6. financial_ledger
-- Unified ledger tracking Advances, Debts, Balance Payments
-- ------------------------------------------------------------------------------
CREATE TABLE financial_ledger (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID REFERENCES small_holders(supplier_id) ON DELETE RESTRICT,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('ADVANCE', 'DEBT', 'PAYOUT')),
    amount DECIMAL(12,2) NOT NULL,
    description TEXT,
    approver_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'CLEARED'))
);

-- ------------------------------------------------------------------------------
-- 7. service_requests
-- Workflows for Fertilizer, Transport, Machinery renting
-- ------------------------------------------------------------------------------
CREATE TABLE service_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID REFERENCES small_holders(supplier_id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('FERTILIZER', 'TRANSPORT', 'MACHINE_RENT', 'ADVISORY', 'ADVANCE')),
    item_id UUID REFERENCES inventory(item_id) ON DELETE SET NULL,
    quantity INTEGER,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED_BY_EXT', 'DISPATCHED', 'REJECTED')),
    created_by_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);