-- =====================================================================
-- CORTIS - Physical model (PostgreSQL 14+)
-- Built from the logical model + business rules (R1..R21).
--
-- Conventions
--   * tables and columns in English snake_case; tables are plural
--   * primary keys are named <entity>_id (artist_id, order_id, ...)
--   * money      -> NUMERIC(p,2)
--   * timestamps -> TIMESTAMPTZ (stored with time zone)
--   * "enums"    -> VARCHAR + CHECK (easier to evolve than CREATE TYPE),
--                   values in UPPER_SNAKE_CASE so they map 1:1 to Kotlin
--                   enum class names (e.g. OrderStatus.PENDING_PAYMENT)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. LOYALTY LEVELS - must exist before fans
-- ---------------------------------------------------------------------
CREATE TABLE loyalty_levels (
    level_id       SMALLINT    PRIMARY KEY,                -- fixed ids (seed below)
    name           VARCHAR(30) NOT NULL UNIQUE,
    minimum_points INTEGER     NOT NULL UNIQUE CHECK (minimum_points >= 0),
    description    TEXT
);

-- R17: every new fan starts as Bronze => Bronze is id 1 with minimum 0 points.
-- ATTENTION: Silver/Gold/Platinum and their thresholds are PLACEHOLDERS.
INSERT INTO loyalty_levels (level_id, name, minimum_points, description) VALUES
    (1, 'Bronze',      0, 'Starting level for every new fan'),
    (2, 'Silver',   1000, 'Placeholder - adjust to the business'),
    (3, 'Gold',     5000, 'Placeholder - adjust to the business'),
    (4, 'Platinum', 15000, 'Placeholder - adjust to the business');

-- ---------------------------------------------------------------------
-- 2. ARTISTS, MEMBERS AND DEBUTS
-- ---------------------------------------------------------------------
-- R5: an artist is either a SOLO act or a GROUP.
CREATE TABLE artists (
    artist_id   INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    artist_type VARCHAR(5)   NOT NULL CHECK (artist_type IN ('SOLO', 'GROUP')),
    company     VARCHAR(100),
    country     VARCHAR(60)
);

CREATE TABLE members (
    member_id   INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stage_name  VARCHAR(100) NOT NULL,
    birth_date  DATE,
    nationality VARCHAR(60),
    debut_date  DATE
);

-- N:M between artists and members (a member can be in a group and a sub-unit,
-- or have a solo career). A SOLO artist = an artist with exactly 1 member.
CREATE TABLE artist_members (
    artist_id  INTEGER NOT NULL REFERENCES artists(artist_id) ON DELETE CASCADE,
    member_id  INTEGER NOT NULL REFERENCES members(member_id) ON DELETE RESTRICT,
    join_date  DATE,
    leave_date DATE,
    PRIMARY KEY (artist_id, member_id),
    CHECK (leave_date IS NULL OR join_date IS NULL OR leave_date >= join_date)
);

-- R7: an artist can have several debuts (debut, re-debut, sub-unit, solo...).
CREATE TABLE debuts (
    debut_id    INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_id   INTEGER     NOT NULL REFERENCES artists(artist_id) ON DELETE CASCADE,
    debut_date  DATE        NOT NULL,
    debut_type  VARCHAR(10) NOT NULL DEFAULT 'DEBUT'
                            CHECK (debut_type IN ('DEBUT', 'RE_DEBUT', 'SUB_UNIT', 'SOLO')),
    description TEXT,
    UNIQUE (artist_id, debut_date, debut_type)
);

-- ---------------------------------------------------------------------
-- 3. PRODUCTS, EVENTS AND TICKETS
-- ---------------------------------------------------------------------
-- R8: name, price and availability (stock) are mandatory.
CREATE TABLE products (
    product_id INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_id  INTEGER       NOT NULL REFERENCES artists(artist_id) ON DELETE RESTRICT,
    name       VARCHAR(150)  NOT NULL,
    price      NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    category   VARCHAR(50),
    stock      INTEGER       NOT NULL DEFAULT 0 CHECK (stock >= 0)   -- never negative => no overselling
);

-- R13: every event belongs to exactly one artist/group.
CREATE TABLE events (
    event_id    INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_id   INTEGER      NOT NULL REFERENCES artists(artist_id) ON DELETE RESTRICT,
    name        VARCHAR(150) NOT NULL,
    description TEXT,
    venue       VARCHAR(200),
    start_date  TIMESTAMPTZ  NOT NULL,
    end_date    TIMESTAMPTZ  NOT NULL,
    event_type  VARCHAR(20)  NOT NULL
                CHECK (event_type IN ('CONCERT', 'FESTIVAL', 'FAN_MEETING', 'ALBUM_RELEASE',
                                      'LIVE_STREAM', 'FAN_SIGN', 'SHOWCASE', 'POP_UP_EVENT')),
    CHECK (end_date >= start_date)
);

-- Each row is a ticket CATEGORY of an event (e.g. VIP, Standard) with an
-- available quantity, NOT an individual ticket.
CREATE TABLE tickets (
    ticket_id          INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id           INTEGER       NOT NULL REFERENCES events(event_id) ON DELETE RESTRICT,
    ticket_type        VARCHAR(10)   NOT NULL
                                     CHECK (ticket_type IN ('STANDARD', 'VIP', 'PREMIUM', 'VVIP', 'STUDENT')),
    price              NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    status             VARCHAR(10)   NOT NULL DEFAULT 'AVAILABLE'
                                     CHECK (status IN ('AVAILABLE', 'SOLD_OUT', 'CLOSED')),
    quantity_available INTEGER       NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    benefits           TEXT,
    UNIQUE (event_id, ticket_type)
);

-- ---------------------------------------------------------------------
-- 4. FANS, ADDRESSES AND PAYMENT METHODS
-- ---------------------------------------------------------------------
CREATE TABLE fans (
    fan_id           INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    level_id         SMALLINT     NOT NULL DEFAULT 1                    -- R17: Bronze
                                  REFERENCES loyalty_levels(level_id),
    first_name       VARCHAR(60)  NOT NULL,                             -- R1
    last_name        VARCHAR(100) NOT NULL,                             -- R1
    email            VARCHAR(255) NOT NULL CHECK (email ~* '^[^@\s]+@[^@\s]+$'),
    password_hash    VARCHAR(255) NOT NULL,                             -- R3: hash (bcrypt/argon2), never plain text
    phone            VARCHAR(20),                                       -- R4: optional
    birth_date       DATE,                                              -- optional (not in R1)
    account_created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    current_points   INTEGER      NOT NULL DEFAULT 0 CHECK (current_points >= 0),   -- R21: balance never negative
    lifetime_points  INTEGER      NOT NULL DEFAULT 0 CHECK (lifetime_points >= 0)   -- total ever earned (defines the level)
);
-- R2: unique e-mail, case-insensitive.
CREATE UNIQUE INDEX uq_fans_email ON fans (lower(email));

-- R4: address is optional (a fan can have 0..N).
CREATE TABLE addresses (
    address_id   INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fan_id       INTEGER      NOT NULL REFERENCES fans(fan_id) ON DELETE CASCADE,
    postal_code  VARCHAR(12)  NOT NULL,
    street       VARCHAR(150) NOT NULL,
    street_number VARCHAR(10) NOT NULL,
    complement   VARCHAR(100),
    neighborhood VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    state        VARCHAR(50)  NOT NULL,
    country      VARCHAR(60)  NOT NULL DEFAULT 'Brazil',
    label        VARCHAR(50),                    -- e.g. "Home", "Work"
    is_primary   BOOLEAN      NOT NULL DEFAULT FALSE,
    UNIQUE (address_id, fan_id)                  -- lets an order guarantee the address belongs to the same fan
);
-- at most 1 primary address per fan
CREATE UNIQUE INDEX uq_addresses_primary ON addresses (fan_id) WHERE is_primary;

-- Never store the full card number or CVV: only the last 4 digits and the brand.
CREATE TABLE payment_methods (
    payment_method_id INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fan_id            INTEGER     NOT NULL REFERENCES fans(fan_id) ON DELETE CASCADE,
    payment_type      VARCHAR(20) NOT NULL
                                  CHECK (payment_type IN ('CREDIT_CARD', 'DEBIT_CARD', 'PIX', 'BANK_TRANSFER', 'BOLETO')),
    label             VARCHAR(50),                                -- e.g. "Visa Nubank"
    card_last4        CHAR(4)     CHECK (card_last4 ~ '^[0-9]{4}$'),
    card_brand        VARCHAR(20),                                -- Visa, Mastercard...
    is_active         BOOLEAN     NOT NULL DEFAULT TRUE,          -- "delete" = deactivate (keeps history)
    CHECK (payment_type NOT IN ('CREDIT_CARD', 'DEBIT_CARD')
           OR (card_last4 IS NOT NULL AND card_brand IS NOT NULL))
);

-- ---------------------------------------------------------------------
-- 5. ORDERS, ITEMS AND PAYMENT TRANSACTIONS
-- ---------------------------------------------------------------------
-- R10: each order belongs to a single fan.
CREATE TABLE orders (
    order_id        BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fan_id          INTEGER       NOT NULL REFERENCES fans(fan_id) ON DELETE RESTRICT,
    address_id      INTEGER,                                      -- delivery; NULL on ticket-only orders
    order_date      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING_PAYMENT'
                                  CHECK (status IN ('PENDING_PAYMENT', 'PAID', 'PROCESSING',
                                                    'SHIPPED', 'DELIVERED', 'CANCELLED')),
    shipping_method VARCHAR(10)   CHECK (shipping_method IN ('STANDARD', 'EXPRESS', 'ECONOMY',
                                                             'SAME_DAY', 'PICKUP')),   -- NULL on ticket-only orders
    shipping_fee    NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
    total_value     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_value >= 0),   -- R12: maintained by trigger, do NOT send via API
    -- guarantees the delivery address belongs to the order's fan (ignored when address_id is NULL)
    FOREIGN KEY (address_id, fan_id) REFERENCES addresses (address_id, fan_id) ON DELETE RESTRICT,
    -- anything shipped (not pickup) needs a delivery address
    CHECK (shipping_method IS NULL OR shipping_method = 'PICKUP' OR address_id IS NOT NULL)
);

CREATE TABLE order_items (
    order_item_id BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      BIGINT        NOT NULL REFERENCES orders(order_id)      ON DELETE CASCADE,
    product_id    INTEGER       NOT NULL REFERENCES products(product_id)  ON DELETE RESTRICT,
    quantity      INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),   -- price "snapshot" at purchase time
    UNIQUE (order_id, product_id)
);

CREATE TABLE order_ticket_items (
    order_ticket_item_id BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id             BIGINT        NOT NULL REFERENCES orders(order_id)    ON DELETE CASCADE,
    ticket_id            INTEGER       NOT NULL REFERENCES tickets(ticket_id)  ON DELETE RESTRICT,
    quantity             INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price           NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, ticket_id)
);

-- R16: a ticket order requires payment. An order can have several attempts
-- (e.g. 1st DECLINED, 2nd APPROVED), hence 1:N.
CREATE TABLE payment_transactions (
    transaction_id    BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id          BIGINT        NOT NULL REFERENCES orders(order_id)                      ON DELETE RESTRICT,
    payment_method_id INTEGER       NOT NULL REFERENCES payment_methods(payment_method_id)    ON DELETE RESTRICT,
    amount            NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    transaction_date  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    status            VARCHAR(10)   NOT NULL DEFAULT 'PENDING'
                                    CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED', 'REFUNDED')),
    gateway_code      VARCHAR(100)  UNIQUE,            -- returned by the payment gateway (NULL until it exists)
    installments      SMALLINT      NOT NULL DEFAULT 1 CHECK (installments >= 1)
);

-- ---------------------------------------------------------------------
-- 6. INTERACTIONS, REWARDS AND POINTS
-- ---------------------------------------------------------------------
-- R19: each row is an interaction that happened (log) and stores the points granted at the time.
CREATE TABLE interactions (
    interaction_id   BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fan_id           INTEGER      NOT NULL REFERENCES fans(fan_id) ON DELETE CASCADE,
    name             VARCHAR(100) NOT NULL,
    category         VARCHAR(50),
    description      TEXT,
    points_earned    INTEGER      NOT NULL DEFAULT 0 CHECK (points_earned >= 0),
    interaction_date TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- R20: catalog of rewards that can be redeemed with points.
CREATE TABLE rewards (
    reward_id   INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    description TEXT,
    points_cost INTEGER      NOT NULL CHECK (points_cost > 0),
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE redemptions (
    redemption_id BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fan_id        INTEGER     NOT NULL REFERENCES fans(fan_id)        ON DELETE RESTRICT,
    reward_id     INTEGER     NOT NULL REFERENCES rewards(reward_id)  ON DELETE RESTRICT,
    points_spent  INTEGER     NOT NULL CHECK (points_spent > 0),   -- "snapshot" of the cost at redemption time
    redeemed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    status        VARCHAR(10) NOT NULL DEFAULT 'REQUESTED'
                              CHECK (status IN ('REQUESTED', 'COMPLETED', 'CANCELLED'))
);

-- Points statement (+ earned / - spent). Every balance change goes through here;
-- the trigger fn_apply_points_entry updates fans.current_points/lifetime_points/level.
CREATE TABLE points_ledger (
    entry_id       BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fan_id         INTEGER     NOT NULL REFERENCES fans(fan_id) ON DELETE RESTRICT,
    entry_type     VARCHAR(15) NOT NULL CHECK (entry_type IN ('PURCHASE', 'INTERACTION', 'REDEMPTION', 'REFUND', 'ADJUSTMENT')),
    points         INTEGER     NOT NULL CHECK (points <> 0),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    description    TEXT,
    order_id       BIGINT      REFERENCES orders(order_id)             ON DELETE RESTRICT,
    interaction_id BIGINT      REFERENCES interactions(interaction_id) ON DELETE RESTRICT,
    redemption_id  BIGINT      REFERENCES redemptions(redemption_id)   ON DELETE RESTRICT,
    CHECK (
        num_nonnulls(order_id, interaction_id, redemption_id) <= 1
        AND (entry_type <> 'PURCHASE'    OR (order_id       IS NOT NULL AND points > 0))
        AND (entry_type <> 'INTERACTION' OR (interaction_id IS NOT NULL AND points > 0))
        AND (entry_type <> 'REDEMPTION'  OR (redemption_id  IS NOT NULL AND points < 0))
    )
);
-- prevents crediting the same source twice (idempotency)
CREATE UNIQUE INDEX uq_ledger_purchase    ON points_ledger (order_id)       WHERE entry_type = 'PURCHASE';
CREATE UNIQUE INDEX uq_ledger_interaction ON points_ledger (interaction_id) WHERE entry_type = 'INTERACTION';
CREATE UNIQUE INDEX uq_ledger_redemption  ON points_ledger (redemption_id)  WHERE entry_type = 'REDEMPTION';

-- ---------------------------------------------------------------------
-- 7. INDEXES (foreign keys and catalog queries)
-- ---------------------------------------------------------------------
CREATE INDEX ix_debuts_artist           ON debuts (artist_id);
CREATE INDEX ix_artist_members_member   ON artist_members (member_id);
CREATE INDEX ix_products_artist         ON products (artist_id);
CREATE INDEX ix_products_in_stock       ON products (name) WHERE stock > 0;       -- R9
CREATE INDEX ix_events_artist           ON events (artist_id);
CREATE INDEX ix_events_start_date       ON events (start_date);
CREATE INDEX ix_tickets_event           ON tickets (event_id);
CREATE INDEX ix_fans_level              ON fans (level_id);
CREATE INDEX ix_addresses_fan           ON addresses (fan_id);
CREATE INDEX ix_payment_methods_fan     ON payment_methods (fan_id);
CREATE INDEX ix_orders_fan              ON orders (fan_id, order_date DESC);
CREATE INDEX ix_order_items_product     ON order_items (product_id);
CREATE INDEX ix_order_ticket_items_tkt  ON order_ticket_items (ticket_id);
CREATE INDEX ix_order_ticket_items_ord  ON order_ticket_items (order_id);
CREATE INDEX ix_transactions_order      ON payment_transactions (order_id);
CREATE INDEX ix_transactions_method     ON payment_transactions (payment_method_id);
CREATE INDEX ix_interactions_fan        ON interactions (fan_id, interaction_date DESC);
CREATE INDEX ix_redemptions_fan         ON redemptions (fan_id);
CREATE INDEX ix_redemptions_reward      ON redemptions (reward_id);
CREATE INDEX ix_ledger_fan              ON points_ledger (fan_id, created_at DESC);

-- ---------------------------------------------------------------------
-- 8. QUERY VIEWS
-- ---------------------------------------------------------------------
-- R9: products available for purchase
CREATE VIEW v_available_products AS
SELECT p.product_id, p.name, p.price, p.category, p.stock, a.artist_id, a.name AS artist
FROM products p
JOIN artists a USING (artist_id)
WHERE p.stock > 0;

-- R14: only tickets that can be bought (status, quantity and event not yet started)
CREATE VIEW v_available_tickets AS
SELECT t.ticket_id, t.ticket_type, t.price, t.quantity_available, t.benefits,
       e.event_id, e.name AS event, e.venue, e.start_date
FROM tickets t
JOIN events e USING (event_id)
WHERE t.status = 'AVAILABLE' AND t.quantity_available > 0 AND e.start_date > now();

-- ---------------------------------------------------------------------
-- 9. DATABASE RULES (triggers) - safety net beyond the API
-- ---------------------------------------------------------------------

-- R6: an artist needs at least 1 member.
-- DEFERRED constraint trigger: validates at COMMIT, so create the artist and
-- its members in the SAME transaction.
CREATE FUNCTION fn_require_member() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN v_id := OLD.artist_id; ELSE v_id := NEW.artist_id; END IF;
    IF EXISTS (SELECT 1 FROM artists WHERE artist_id = v_id)
       AND NOT EXISTS (SELECT 1 FROM artist_members WHERE artist_id = v_id) THEN
        RAISE EXCEPTION 'Artist % needs at least one member (R6)', v_id
              USING ERRCODE = 'check_violation';
    END IF;
    RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER ctg_artist_requires_member
    AFTER INSERT ON artists
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_require_member();
CREATE CONSTRAINT TRIGGER ctg_member_removal
    AFTER DELETE ON artist_members
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_require_member();

-- R11: an order needs at least 1 item (product OR ticket). Validated at COMMIT.
CREATE FUNCTION fn_require_order_item() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    IF TG_OP = 'DELETE' THEN v_id := OLD.order_id; ELSE v_id := NEW.order_id; END IF;
    IF EXISTS (SELECT 1 FROM orders WHERE order_id = v_id)
       AND NOT EXISTS (SELECT 1 FROM order_items WHERE order_id = v_id)
       AND NOT EXISTS (SELECT 1 FROM order_ticket_items WHERE order_id = v_id) THEN
        RAISE EXCEPTION 'Order % needs at least one item (R11)', v_id
              USING ERRCODE = 'check_violation';
    END IF;
    RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER ctg_order_requires_item
    AFTER INSERT ON orders
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_require_order_item();
CREATE CONSTRAINT TRIGGER ctg_order_item_removal
    AFTER DELETE ON order_items
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_require_order_item();
CREATE CONSTRAINT TRIGGER ctg_order_ticket_item_removal
    AFTER DELETE ON order_ticket_items
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_require_order_item();

-- R12: total_value = sum(quantity * unit_price) of the items + shipping_fee.
CREATE FUNCTION fn_recalc_order_total(p_order_id BIGINT) RETURNS void LANGUAGE sql AS $$
    UPDATE orders o
       SET total_value = o.shipping_fee
           + COALESCE((SELECT SUM(quantity * unit_price) FROM order_items        WHERE order_id = p_order_id), 0)
           + COALESCE((SELECT SUM(quantity * unit_price) FROM order_ticket_items WHERE order_id = p_order_id), 0)
     WHERE o.order_id = p_order_id;
$$;

CREATE FUNCTION fn_trg_total_by_item() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN PERFORM fn_recalc_order_total(OLD.order_id);
    ELSE PERFORM fn_recalc_order_total(NEW.order_id); END IF;
    RETURN NULL;
END $$;

CREATE FUNCTION fn_trg_total_by_shipping() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    PERFORM fn_recalc_order_total(NEW.order_id);
    RETURN NULL;
END $$;

CREATE TRIGGER trg_order_item_total
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW EXECUTE FUNCTION fn_trg_total_by_item();
CREATE TRIGGER trg_order_ticket_item_total
    AFTER INSERT OR UPDATE OR DELETE ON order_ticket_items
    FOR EACH ROW EXECUTE FUNCTION fn_trg_total_by_item();
CREATE TRIGGER trg_order_shipping_total
    AFTER UPDATE OF shipping_fee ON orders
    FOR EACH ROW WHEN (OLD.shipping_fee IS DISTINCT FROM NEW.shipping_fee)
    EXECUTE FUNCTION fn_trg_total_by_shipping();

-- R14: only sells tickets whose status is AVAILABLE.
-- The quantity is protected by CHECK (quantity_available >= 0): the API must insert
-- the item and then run
--   UPDATE tickets SET quantity_available = quantity_available - :n
--    WHERE ticket_id = :id AND quantity_available >= :n;   (0 rows => ROLLBACK)
CREATE FUNCTION fn_validate_ticket_available() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tickets
                    WHERE ticket_id = NEW.ticket_id AND status = 'AVAILABLE') THEN
        RAISE EXCEPTION 'Ticket % is not available for sale (R14)', NEW.ticket_id
              USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_order_ticket_item_available
    BEFORE INSERT ON order_ticket_items
    FOR EACH ROW EXECUTE FUNCTION fn_validate_ticket_available();

-- R18-R21: every point earned/spent enters points_ledger; this trigger updates
-- the balance, the lifetime total and the level. If the balance would go negative,
-- the CHECK on fans.current_points aborts the transaction (R21: insufficient balance).
-- The level is based on LIFETIME points, so redeeming never moves a fan "down".
CREATE FUNCTION fn_apply_points_entry() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE fans f
       SET current_points  = f.current_points + NEW.points,
           lifetime_points = f.lifetime_points + GREATEST(NEW.points, 0),
           level_id = COALESCE(
               (SELECT l.level_id FROM loyalty_levels l
                 WHERE l.minimum_points <= f.lifetime_points + GREATEST(NEW.points, 0)
                 ORDER BY l.minimum_points DESC LIMIT 1),
               f.level_id)
     WHERE f.fan_id = NEW.fan_id;
    RETURN NULL;
END $$;

CREATE TRIGGER trg_points_ledger
    AFTER INSERT ON points_ledger
    FOR EACH ROW EXECUTE FUNCTION fn_apply_points_entry();
