-- ENUMS
-------------------------------------------------------------------------------
CREATE TYPE oven_status AS ENUM ('idle', 'busy', 'overheated');
CREATE TYPE order_status AS ENUM ('pending', 'baking', 'completed', 'rejected');
CREATE TYPE order_event_type AS ENUM (
    'created',         -- Order received 
    'stock_reserved',  -- Stock available
    'baking_started',  -- Entered the oven
    'oven_overheated', -- Oven failure
    'completed',
    'rejected'         -- No stock available
);

-------------------------------------------------------------------------------
-- 2. TABLES
-------------------------------------------------------------------------------

-- PIZZAS: Inventory and Metadata
CREATE TABLE pizzas (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    prep_time_seconds INT NOT NULL CHECK (prep_time_seconds > 0),
    initial_stock INT NOT NULL CHECK (initial_stock >= 0),
    current_stock INT NOT NULL CHECK (current_stock >= 0),
    CONSTRAINT stock_sanity_check CHECK (current_stock <= initial_stock)
);

-- OVENS: State and Health
CREATE TABLE ovens (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status oven_status NOT NULL DEFAULT 'idle',
    current_temperature_celsius INT NOT NULL
        CHECK (current_temperature_celsius BETWEEN 0 AND 500),
    available_at TIMESTAMPTZ,
    total_pizzas_completed INT NOT NULL DEFAULT 0
        CHECK (total_pizzas_completed >= 0),
    last_overheat_at TIMESTAMPTZ
);

-- ORDERS: Primary transaction table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trace_id UUID NOT NULL,
    customer_id INT NOT NULL DEFAULT (floor(random() * 500) + 1)::int,
    pizza_id INT NOT NULL REFERENCES pizzas(id),
    oven_id INT REFERENCES ovens(id),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    duration_ms INT CHECK (duration_ms >= 0)
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

-- SYSTEM METRICS: Snapshots
CREATE TABLE system_metrics (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    queue_depth INT NOT NULL CHECK (queue_depth >= 0),
    busy_ovens INT NOT NULL CHECK (busy_ovens >= 0),
    overheated_ovens INT NOT NULL CHECK (overheated_ovens >= 0),
    total_orders_completed INT NOT NULL CHECK (total_orders_completed >= 0),
    total_orders_rejected INT NOT NULL CHECK (total_orders_rejected >= 0),
    avg_latency_ms DOUBLE PRECISION,
    orders_per_minute DOUBLE PRECISION
);

-------------------------------------------------------------------------------
-- 3. INDEXES
-------------------------------------------------------------------------------

-- Active baking orders per oven
CREATE INDEX idx_active_orders_per_oven
    ON orders (oven_id)
    WHERE status = 'baking';

CREATE INDEX idx_orders_status_created
    ON orders (status, created_at);

CREATE INDEX idx_orders_trace
    ON orders (trace_id);

CREATE INDEX idx_order_events_trace
    ON order_events (trace_id, timestamp DESC);

CREATE INDEX idx_order_events_order
    ON order_events (order_id, timestamp DESC);

CREATE INDEX idx_system_metrics_timestamp
    ON system_metrics (timestamp DESC);

-------------------------------------------------------------------------------
-- 4. FUNCTIONS & TRIGGERS
-------------------------------------------------------------------------------

-- Atomically decrement pizza stock on order creation
CREATE OR REPLACE FUNCTION decrement_pizza_stock()
RETURNS TRIGGER AS $$
DECLARE
    rows_affected INT;
BEGIN
    UPDATE pizzas
    SET current_stock = current_stock - 1
    WHERE id = NEW.pizza_id
      AND current_stock > 0;

    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    IF rows_affected = 0 THEN
        RAISE EXCEPTION 'Pizza % is out of stock', NEW.pizza_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrement_stock
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION decrement_pizza_stock();

-- Calculate order duration on completion
CREATE OR REPLACE FUNCTION calculate_order_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed'
       AND OLD.status IS DISTINCT FROM 'completed' THEN
        NEW.completed_at = NOW();
        NEW.duration_ms =
            EXTRACT(EPOCH FROM (NEW.completed_at - NEW.created_at)) * 1000;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_duration
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION calculate_order_duration();

-- For automatically creating an order event whenever an order is inserted or its status changes
CREATE OR REPLACE FUNCTION log_order_event()
RETURNS TRIGGER AS $$
DECLARE
    derived_event order_event_type;
BEGIN
    IF TG_OP = 'INSERT' THEN
        derived_event := 'created';

    ELSIF OLD.status IS DISTINCT FROM NEW.status THEN
        CASE NEW.status
            WHEN 'baking'   THEN derived_event := 'baking_started';
            WHEN 'completed' THEN derived_event := 'completed';
            WHEN 'rejected'  THEN derived_event := 'rejected';
            ELSE
                derived_event := NULL;
        END CASE;
    END IF;

    IF derived_event IS NOT NULL THEN
        INSERT INTO order_events (
            order_id,
            trace_id,
            event_type,
            oven_id
        )
        VALUES (
            NEW.id,
            NEW.trace_id,
            derived_event,
            NEW.oven_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_order_event
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION log_order_event();
