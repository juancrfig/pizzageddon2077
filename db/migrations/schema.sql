-- -------------------------------------------------------------------------------
-- ENUMS
-- -------------------------------------------------------------------------------
CREATE TYPE oven_status AS ENUM ('idle', 'busy', 'overheated');
CREATE TYPE order_status AS ENUM ('pending', 'baking', 'completed', 'rejected');
CREATE TYPE order_event_type AS ENUM (
    'created',
    'stock_reserved',
    'baking_started',
    'oven_overheated',
    'completed',
    'rejected'
);

-- -------------------------------------------------------------------------------
-- TABLES
-- -------------------------------------------------------------------------------

-- PIZZAS: Inventory and Metadata
CREATE TABLE pizzas (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    prep_time_seconds INT NOT NULL CHECK (prep_time_seconds > 0),
    initial_stock INT NOT NULL CHECK (initial_stock >= 0),
    current_stock INT NOT NULL CHECK (current_stock >= 0)
);

-- OVENS: State
CREATE TABLE ovens (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status oven_status NOT NULL DEFAULT 'idle',
    current_temperature_celsius INT NOT NULL DEFAULT 200,
    total_pizzas_completed INT NOT NULL DEFAULT 0
);

-- ORDERS: Primary transaction table
CREATE TABLE orders (
    id UUID PRIMARY KEY, -- Go will generate this UUID
    trace_id UUID NOT NULL,
    customer_id INT NOT NULL,
    pizza_id INT NOT NULL REFERENCES pizzas(id),
    oven_id INT REFERENCES ovens(id),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,   -- Go must update this when worker picks it up
    completed_at TIMESTAMPTZ, -- Go must update this when finished
    duration_ms INT           -- Go must calculate this: (completed_at - created_at)
);

-- ORDER EVENTS: Audit Log
CREATE TABLE order_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    trace_id UUID NOT NULL,
    event_type order_event_type NOT NULL,
    oven_id INT REFERENCES ovens(id),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB
);

-- -------------------------------------------------------------------------------
-- 3. INDEXES
-- -------------------------------------------------------------------------------
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_orders_trace ON orders (trace_id);
