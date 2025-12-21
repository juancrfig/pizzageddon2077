CREATE TABLE pizzas (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    prep_time_seconds INT NOT NULL CHECK (prep_time_seconds > 0),
    initial_stock INT NOT NULL CHECK (initial_stock >= 0),
    current_stock INT NOT NULL CHECK (current_stock >= 0),
    CONSTRAINT stock_not_exceeded CHECK (current_stock <= initial_stock)
);

CREATE TYPE oven_status AS ENUM ('idle', 'busy', 'overheated');

CREATE TABLE ovens (
    id SERIAL PRIMARY KEY,
    status oven_status NOT NULL DEFAULT 'idle',
    current_temperature_celsius INT NOT NULL DEFAULT 50,     -- starts cool
    available_at TIMESTAMP,                                 -- NULL = available immediately
    current_order_id UUID,                                  -- NULL if idle/not baking
    total_pizzas_completed INT NOT NULL DEFAULT 0,
    last_overheat_at TIMESTAMP
);

CREATE TYPE order_status AS ENUM ('pending', 'assigned', 'baking', 'completed', 'rejected');

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),           -- or SERIAL if you prefer
    trace_id UUID NOT NULL,                                  -- for tracing entire journey
    customer_id VARCHAR(100) NOT NULL,                       -- e.g., 'cust_4839'
    pizza_id INT NOT NULL REFERENCES pizzas(id),
    oven_id INT REFERENCES ovens(id),                        -- NULL until assigned
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    assigned_at TIMESTAMP,                                   -- when oven claimed
    started_at TIMESTAMP,                                    -- when baking begins
    completed_at TIMESTAMP,                                  -- when done or rejected
    duration_ms INT,                                         -- computed on completion: end-to-end latency
    INDEX idx_orders_status_created (status, created_at),
    INDEX idx_orders_trace (trace_id)
);

CREATE TYPE order_event_type AS ENUM (
    'created',              -- Order arrived via gRPC
    'stock_reserved',       -- Pizza stock successfully decremented
    'out_of_stock',         -- Rejection because no pizza left
    'queued',               -- No oven available, waiting
    'assigned_to_oven',     -- Oven claimed
    'baking_started',       -- Simulation sleep began
    'oven_overheated',      -- Random failure during baking
    'baking_completed',     -- Pizza done
    'completed',            -- Order fully finished
    'rejected',             -- Final rejection (only for out_of_stock)
    'requeued'              -- After overheat, back to queue
);

CREATE TABLE order_events (
    id BIGSERIAL PRIMARY KEY,                       -- fast auto-increment
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    trace_id UUID NOT NULL,                         -- for tracing
    event_type order_event_type NOT NULL,
    oven_id INT REFERENCES ovens(id),               -- NULL if not relevant
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB                                          -- flexible extra data
);

-- Indexes for performance (this table will grow fast)
CREATE INDEX idx_order_events_trace ON order_events(trace_id, timestamp DESC);
CREATE INDEX idx_order_events_order ON order_events(order_id, timestamp DESC);
CREATE INDEX idx_order_events_timestamp ON order_events(timestamp DESC);
CREATE INDEX idx_order_events_type ON order_events(event_type);

CREATE TABLE system_metrics (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    queue_depth INT NOT NULL,                    -- COUNT of pending/queued orders
    active_ovens INT NOT NULL,                   -- idle + busy
    busy_ovens INT NOT NULL,
    overheated_ovens INT NOT NULL,
    total_orders_completed INT NOT NULL,         -- cumulative successful orders
    total_orders_rejected INT NOT NULL,          -- cumulative rejections
    avg_latency_ms FLOAT,                        -- average duration_ms last minute (or since start)
    orders_per_minute FLOAT                      -- throughput last minute
);

CREATE INDEX idx_system_metrics_timestamp ON system_metrics(timestamp DESC);
