-- APANPS5310 SQL Class Project - Project Checkpoint 3
-- Topic 1: ABC Foodmart
-- Locked 19-table PostgreSQL candidate schema with sample data

DROP SCHEMA IF EXISTS abc_foodmart CASCADE;
CREATE SCHEMA abc_foodmart;
SET search_path TO abc_foodmart;

CREATE TABLE stores (
    store_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_name          VARCHAR(120) NOT NULL UNIQUE,
    borough             VARCHAR(40) NOT NULL CHECK (borough IN ('Queens', 'Brooklyn')),
    street_address      VARCHAR(200) NOT NULL,
    city                VARCHAR(80) NOT NULL DEFAULT 'New York',
    state               CHAR(2) NOT NULL DEFAULT 'NY',
    zip_code            VARCHAR(10) NOT NULL,
    opening_time        TIME NOT NULL,
    closing_time        TIME NOT NULL,
    operational_status  VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (operational_status IN ('planned', 'active', 'temporarily_closed', 'closed')),
    CHECK (opening_time < closing_time)
);

CREATE TABLE job_roles (
    role_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name           VARCHAR(80) NOT NULL UNIQUE,
    role_description    TEXT
);

CREATE TABLE employees (
    employee_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    role_id             BIGINT NOT NULL REFERENCES job_roles(role_id),
    first_name          VARCHAR(80) NOT NULL,
    last_name           VARCHAR(80) NOT NULL,
    email               VARCHAR(160) UNIQUE,
    hire_date           DATE NOT NULL,
    hourly_pay_rate     NUMERIC(8,2) NOT NULL CHECK (hourly_pay_rate >= 0),
    employment_status   VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (employment_status IN ('active', 'on_leave', 'terminated'))
);

CREATE TABLE staff_shifts (
    shift_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id         BIGINT NOT NULL REFERENCES employees(employee_id),
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    scheduled_start     TIMESTAMP NOT NULL,
    scheduled_end       TIMESTAMP NOT NULL,
    actual_start        TIMESTAMP,
    actual_end          TIMESTAMP,
    shift_status        VARCHAR(20) NOT NULL DEFAULT 'scheduled'
        CHECK (shift_status IN ('scheduled', 'completed', 'cancelled', 'missed')),
    CHECK (scheduled_end > scheduled_start),
    CHECK (actual_end IS NULL OR actual_start IS NULL OR actual_end > actual_start)
);


CREATE TABLE time_off_requests (
    request_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id         BIGINT NOT NULL REFERENCES employees(employee_id),
    request_date        DATE NOT NULL DEFAULT CURRENT_DATE,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    reason              TEXT,
    request_status      VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (request_status IN ('pending', 'approved', 'denied', 'cancelled')),
    review_date         DATE,
    CHECK (end_date >= start_date),
    CHECK (review_date IS NULL OR review_date >= request_date),
    CHECK (request_status IN ('pending', 'cancelled') OR review_date IS NOT NULL)
);

CREATE TABLE product_categories (
    category_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name       VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id         BIGINT NOT NULL REFERENCES product_categories(category_id),
    product_name        VARCHAR(160) NOT NULL,
    brand               VARCHAR(100),
    unit_size           VARCHAR(60) NOT NULL,
    retail_price        NUMERIC(10,2) NOT NULL CHECK (retail_price >= 0),
    active_flag         BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (product_name, brand, unit_size)
);

CREATE TABLE store_inventory (
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    product_id          BIGINT NOT NULL REFERENCES products(product_id),
    quantity_on_hand    INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    reorder_threshold   INTEGER NOT NULL DEFAULT 0 CHECK (reorder_threshold >= 0),
    PRIMARY KEY (store_id, product_id)
);

CREATE TABLE inventory_adjustments (
    adjustment_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    product_id          BIGINT NOT NULL REFERENCES products(product_id),
    adjustment_time     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    adjustment_type     VARCHAR(20) NOT NULL
        CHECK (adjustment_type IN ('sale', 'return', 'damage', 'expired', 'delivery', 'manual_count')),
    quantity_delta      INTEGER NOT NULL CHECK (quantity_delta <> 0),
    notes               TEXT
);

CREATE TABLE vendors (
    vendor_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendor_name         VARCHAR(160) NOT NULL UNIQUE,
    contact_name        VARCHAR(120),
    email               VARCHAR(160),
    phone               VARCHAR(20),
    vendor_status       VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (vendor_status IN ('active', 'inactive'))
);

CREATE TABLE vendor_products (
    vendor_product_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendor_id           BIGINT NOT NULL REFERENCES vendors(vendor_id),
    product_id          BIGINT NOT NULL REFERENCES products(product_id),
    unit_purchase_cost  NUMERIC(10,2) NOT NULL CHECK (unit_purchase_cost >= 0),
    min_order_quantity  INTEGER NOT NULL DEFAULT 1 CHECK (min_order_quantity > 0),
    lead_time_days      INTEGER NOT NULL CHECK (lead_time_days >= 0),
    UNIQUE (vendor_id, product_id)
);

CREATE TABLE purchase_orders (
    purchase_order_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendor_id           BIGINT NOT NULL REFERENCES vendors(vendor_id),
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    order_date          DATE NOT NULL,
    expected_date       DATE,
    received_date       DATE,
    order_status        VARCHAR(20) NOT NULL DEFAULT 'submitted'
        CHECK (order_status IN ('draft', 'submitted', 'partially_received', 'received', 'cancelled')),
    CHECK (expected_date IS NULL OR expected_date >= order_date),
    CHECK (received_date IS NULL OR received_date >= order_date)
);

CREATE TABLE purchase_order_items (
    purchase_order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id   BIGINT NOT NULL REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE,
    vendor_product_id   BIGINT NOT NULL REFERENCES vendor_products(vendor_product_id),
    quantity_ordered    INTEGER NOT NULL CHECK (quantity_ordered > 0),
    quantity_received   INTEGER NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
    quantity_damaged    INTEGER NOT NULL DEFAULT 0 CHECK (quantity_damaged >= 0),
    quantity_missing    INTEGER NOT NULL DEFAULT 0 CHECK (quantity_missing >= 0),
    unit_purchase_cost  NUMERIC(10,2) NOT NULL CHECK (unit_purchase_cost >= 0),
    UNIQUE (purchase_order_id, vendor_product_id),
    CHECK (quantity_received <= quantity_ordered),
    CHECK (quantity_damaged <= quantity_received)
);

CREATE TABLE deliveries (
    delivery_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id   BIGINT NOT NULL REFERENCES purchase_orders(purchase_order_id),
    delivery_date       DATE NOT NULL,
    delivery_status     VARCHAR(20) NOT NULL DEFAULT 'received'
        CHECK (delivery_status IN ('received', 'partial', 'rejected')),
    notes               TEXT
);

CREATE TABLE sales_transactions (
    sale_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    sale_time           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sale_status         VARCHAR(20) NOT NULL DEFAULT 'completed'
        CHECK (sale_status IN ('completed', 'voided', 'refunded', 'partially_refunded')),
    subtotal_amount     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (subtotal_amount >= 0),
    discount_amount     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    tax_amount          NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    refund_amount       NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (refund_amount >= 0),
    total_amount        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    CHECK (discount_amount <= subtotal_amount),
    CHECK (refund_amount <= total_amount)
);

CREATE TABLE sales_items (
    sale_item_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_id             BIGINT NOT NULL REFERENCES sales_transactions(sale_id) ON DELETE CASCADE,
    product_id          BIGINT NOT NULL REFERENCES products(product_id),
    quantity_sold       INTEGER NOT NULL CHECK (quantity_sold > 0),
    unit_retail_price   NUMERIC(10,2) NOT NULL CHECK (unit_retail_price >= 0),
    item_discount       NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (item_discount >= 0),
    UNIQUE (sale_id, product_id),
    CHECK (item_discount <= quantity_sold * unit_retail_price)
);


CREATE TABLE customer_returns (
    return_id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_item_id                 BIGINT NOT NULL REFERENCES sales_items(sale_item_id),
    processed_by_employee_id     BIGINT NOT NULL REFERENCES employees(employee_id),
    return_time                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantity_returned            INTEGER NOT NULL CHECK (quantity_returned > 0),
    refund_amount                NUMERIC(12,2) NOT NULL CHECK (refund_amount >= 0),
    return_reason                VARCHAR(200)
);

CREATE TABLE payments (
    payment_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_id             BIGINT NOT NULL REFERENCES sales_transactions(sale_id) ON DELETE CASCADE,
    payment_method      VARCHAR(20) NOT NULL
        CHECK (payment_method IN ('cash', 'credit_card', 'debit_card', 'mobile_pay', 'gift_card')),
    payment_amount      NUMERIC(12,2) NOT NULL CHECK (payment_amount > 0),
    payment_time        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE operating_expenses (
    expense_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_id            BIGINT NOT NULL REFERENCES stores(store_id),
    expense_date        DATE NOT NULL,
    expense_type        VARCHAR(40) NOT NULL
        CHECK (expense_type IN ('rent', 'utilities', 'wages', 'maintenance', 'supplies', 'marketing', 'other')),
    amount              NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    description         TEXT
);

CREATE INDEX idx_employees_store ON employees(store_id);
CREATE INDEX idx_shifts_store_time ON staff_shifts(store_id, scheduled_start);
CREATE INDEX idx_inventory_product ON store_inventory(product_id);
CREATE INDEX idx_sales_store_time ON sales_transactions(store_id, sale_time);
CREATE INDEX idx_sales_items_product ON sales_items(product_id);
CREATE INDEX idx_po_vendor_store ON purchase_orders(vendor_id, store_id);
CREATE INDEX idx_adjustments_store_product ON inventory_adjustments(store_id, product_id, adjustment_time);
CREATE INDEX idx_time_off_employee_dates ON time_off_requests(employee_id, start_date, end_date);
CREATE INDEX idx_customer_returns_sale_item ON customer_returns(sale_item_id);

CREATE OR REPLACE FUNCTION apply_inventory_adjustment()
RETURNS TRIGGER AS $$
DECLARE
    new_quantity INTEGER;
BEGIN
    INSERT INTO abc_foodmart.store_inventory (
        store_id, product_id, quantity_on_hand, reorder_threshold
    )
    VALUES (NEW.store_id, NEW.product_id, 0, 0)
    ON CONFLICT (store_id, product_id) DO NOTHING;

    SELECT quantity_on_hand + NEW.quantity_delta
    INTO new_quantity
    FROM abc_foodmart.store_inventory
    WHERE store_id = NEW.store_id AND product_id = NEW.product_id
    FOR UPDATE;

    IF new_quantity < 0 THEN
        RAISE EXCEPTION 'Inventory cannot be negative for store %, product %', NEW.store_id, NEW.product_id;
    END IF;

    UPDATE abc_foodmart.store_inventory
    SET quantity_on_hand = new_quantity
    WHERE store_id = NEW.store_id AND product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_apply_inventory_adjustment
BEFORE INSERT ON inventory_adjustments
FOR EACH ROW EXECUTE FUNCTION apply_inventory_adjustment();

CREATE OR REPLACE FUNCTION reduce_inventory_after_sale()
RETURNS TRIGGER AS $$
DECLARE
    sale_store_id BIGINT;
    original_sale_time TIMESTAMP;
BEGIN
    SELECT store_id, sale_time
    INTO sale_store_id, original_sale_time
    FROM abc_foodmart.sales_transactions
    WHERE sale_id = NEW.sale_id;

    INSERT INTO abc_foodmart.inventory_adjustments (
        store_id,
        product_id,
        adjustment_time,
        adjustment_type,
        quantity_delta,
        notes
    )
    VALUES (
        sale_store_id,
        NEW.product_id,
        original_sale_time,
        'sale',
        -NEW.quantity_sold,
        'Automatic inventory reduction from sale item ' || NEW.sale_item_id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reduce_inventory_after_sale
AFTER INSERT ON sales_items
FOR EACH ROW EXECUTE FUNCTION reduce_inventory_after_sale();

CREATE OR REPLACE FUNCTION validate_purchase_order_vendor()
RETURNS TRIGGER AS $$
DECLARE
    po_vendor_id BIGINT;
    item_vendor_id BIGINT;
BEGIN
    SELECT vendor_id INTO po_vendor_id
    FROM abc_foodmart.purchase_orders
    WHERE purchase_order_id = NEW.purchase_order_id;

    SELECT vendor_id INTO item_vendor_id
    FROM abc_foodmart.vendor_products
    WHERE vendor_product_id = NEW.vendor_product_id;

    IF po_vendor_id <> item_vendor_id THEN
        RAISE EXCEPTION 'Purchase order item vendor must match purchase order vendor';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_purchase_order_vendor
BEFORE INSERT OR UPDATE ON purchase_order_items
FOR EACH ROW EXECUTE FUNCTION validate_purchase_order_vendor();

CREATE OR REPLACE VIEW low_stock_products AS
SELECT
    s.store_name,
    p.product_name,
    si.quantity_on_hand,
    si.reorder_threshold
FROM store_inventory si
JOIN stores s ON s.store_id = si.store_id
JOIN products p ON p.product_id = si.product_id
WHERE si.quantity_on_hand <= si.reorder_threshold;

CREATE OR REPLACE VIEW daily_store_sales AS
SELECT
    s.store_name,
    st.sale_time::DATE AS sale_date,
    COUNT(*) AS transaction_count,
    SUM(
        CASE
            WHEN st.total_amount > 0 THEN
                (st.subtotal_amount - st.discount_amount)
                - ROUND(
                    st.refund_amount
                    * (st.subtotal_amount - st.discount_amount)
                    / st.total_amount,
                    2
                )
            ELSE 0
        END
    ) AS net_sales
FROM sales_transactions st
JOIN stores s ON s.store_id = st.store_id
WHERE st.sale_status <> 'voided'
GROUP BY s.store_name, st.sale_time::DATE;

CREATE OR REPLACE VIEW vendor_performance_summary AS
WITH purchase_order_level AS (
    SELECT
        po.purchase_order_id,
        po.vendor_id,
        po.order_status,
        po.expected_date,
        po.received_date,
        SUM(poi.quantity_ordered) AS ordered_units,
        SUM(poi.quantity_received) AS received_units,
        SUM(poi.quantity_damaged) AS damaged_units,
        SUM(poi.quantity_missing) AS missing_units
    FROM purchase_orders po
    JOIN purchase_order_items poi
      ON poi.purchase_order_id = po.purchase_order_id
    GROUP BY
        po.purchase_order_id,
        po.vendor_id,
        po.order_status,
        po.expected_date,
        po.received_date
)
SELECT
    v.vendor_name,
    COUNT(*) FILTER (
        WHERE pol.order_status IN ('received', 'partially_received')
    ) AS purchase_order_count,
    AVG(GREATEST(pol.received_date - pol.expected_date, 0)) FILTER (
        WHERE pol.order_status IN ('received', 'partially_received')
    ) AS avg_days_late,
    COALESCE(SUM(pol.ordered_units) FILTER (
        WHERE pol.order_status IN ('received', 'partially_received')
    ), 0)::BIGINT AS ordered_units,
    COALESCE(SUM(pol.received_units) FILTER (
        WHERE pol.order_status IN ('received', 'partially_received')
    ), 0)::BIGINT AS received_units,
    COALESCE(SUM(pol.damaged_units) FILTER (
        WHERE pol.order_status IN ('received', 'partially_received')
    ), 0)::BIGINT AS damaged_units,
    COALESCE(SUM(pol.missing_units) FILTER (
        WHERE pol.order_status IN ('received', 'partially_received')
    ), 0)::BIGINT AS missing_units,
    COUNT(*) FILTER (
        WHERE pol.order_status = 'submitted'
    ) AS open_purchase_order_count,
    COUNT(*) FILTER (
        WHERE pol.order_status = 'cancelled'
    ) AS cancelled_purchase_order_count,
    COUNT(*) AS total_purchase_order_count,
    COALESCE(SUM(pol.ordered_units) FILTER (
        WHERE pol.order_status = 'submitted'
    ), 0)::BIGINT AS open_ordered_units,
    COALESCE(SUM(pol.ordered_units) FILTER (
        WHERE pol.order_status = 'cancelled'
    ), 0)::BIGINT AS cancelled_ordered_units
FROM vendors v
JOIN purchase_order_level pol ON pol.vendor_id = v.vendor_id
GROUP BY v.vendor_name;

INSERT INTO stores (store_name, borough, street_address, zip_code, opening_time, closing_time, operational_status) VALUES
('ABC Foodmart - Flushing', 'Queens', '136-20 Roosevelt Ave', '11354', '08:00', '22:00', 'active'),
('ABC Foodmart - Jamaica', 'Queens', '90-15 Parsons Blvd', '11432', '08:00', '21:00', 'active'),
('ABC Foodmart - Brooklyn Heights', 'Brooklyn', '120 Montague St', '11201', '09:00', '21:00', 'planned');

INSERT INTO job_roles (role_name, role_description) VALUES
('Store Manager', 'Manages store operations and staffing'),
('Cashier', 'Handles checkout and customer payments'),
('Stock Clerk', 'Receives deliveries and maintains shelves'),
('Assistant Manager', 'Supports store manager and daily operations');

INSERT INTO employees (store_id, role_id, first_name, last_name, email, hire_date, hourly_pay_rate, employment_status) VALUES
(1, 1, 'Emily', 'Chen', 'emily.chen@abcfoodmart.com', '2024-01-15', 32.00, 'active'),
(1, 2, 'Jason', 'Lee', 'jason.lee@abcfoodmart.com', '2024-03-02', 19.50, 'active'),
(1, 3, 'Maria', 'Garcia', 'maria.garcia@abcfoodmart.com', '2024-05-12', 20.00, 'active'),
(2, 1, 'Daniel', 'Kim', 'daniel.kim@abcfoodmart.com', '2023-11-20', 33.00, 'active'),
(2, 2, 'Aisha', 'Patel', 'aisha.patel@abcfoodmart.com', '2025-02-01', 19.00, 'active'),
(2, 3, 'Kevin', 'Wong', 'kevin.wong@abcfoodmart.com', '2025-04-18', 20.50, 'active');

INSERT INTO staff_shifts (employee_id, store_id, scheduled_start, scheduled_end, actual_start, actual_end, shift_status) VALUES
(1, 1, '2026-07-20 08:00', '2026-07-20 16:00', '2026-07-20 07:55', '2026-07-20 16:05', 'completed'),
(2, 1, '2026-07-20 10:00', '2026-07-20 18:00', '2026-07-20 10:07', '2026-07-20 18:00', 'completed'),
(3, 1, '2026-07-20 14:00', '2026-07-20 22:00', '2026-07-20 14:00', '2026-07-20 22:00', 'completed'),
(4, 2, '2026-07-20 08:00', '2026-07-20 16:00', '2026-07-20 08:00', '2026-07-20 16:10', 'completed'),
(5, 2, '2026-07-20 11:00', '2026-07-20 19:00', '2026-07-20 11:05', '2026-07-20 19:00', 'completed');


INSERT INTO time_off_requests (
    employee_id, request_date, start_date, end_date, reason, request_status, review_date
) VALUES
(2, '2026-07-21', '2026-07-28', '2026-07-29', 'Personal appointment', 'approved', '2026-07-22'),
(5, '2026-07-24', '2026-08-03', '2026-08-03', 'Personal day', 'pending', NULL);

INSERT INTO product_categories (category_name) VALUES
('Beverages'),
('Snacks'),
('Fresh Produce'),
('Dairy'),
('Household');

INSERT INTO products (category_id, product_name, brand, unit_size, retail_price, active_flag) VALUES
(1, 'Bottled Water', 'PureSpring', '24 pack', 6.99, TRUE),
(1, 'Orange Juice', 'SunValley', '52 oz', 4.49, TRUE),
(2, 'Potato Chips', 'CrispyCo', '8 oz', 3.29, TRUE),
(3, 'Bananas', 'FreshFarm', '1 lb', 0.79, TRUE),
(4, 'Whole Milk', 'DairyBest', '1 gallon', 4.99, TRUE),
(5, 'Paper Towels', 'CleanHome', '6 rolls', 8.99, TRUE);

INSERT INTO store_inventory (store_id, product_id, quantity_on_hand, reorder_threshold) VALUES
(1, 1, 120, 40),
(1, 2, 35, 20),
(1, 3, 28, 30),
(1, 4, 75, 25),
(1, 5, 42, 20),
(1, 6, 18, 15),
(2, 1, 90, 35),
(2, 2, 24, 20),
(2, 3, 40, 25),
(2, 4, 60, 20),
(2, 5, 20, 18),
(2, 6, 12, 15);

INSERT INTO inventory_adjustments (store_id, product_id, adjustment_type, quantity_delta, notes) VALUES
(1, 3, 'damage', -2, 'Two bags damaged during shelf stocking'),
(2, 6, 'manual_count', 3, 'Inventory count correction'),
(1, 4, 'expired', -5, 'Expired bananas removed');

INSERT INTO vendors (vendor_name, contact_name, email, phone, vendor_status) VALUES
('Metro Grocery Supply', 'Robert Miles', 'orders@metrogrocery.com', '718-555-0101', 'active'),
('Fresh Farm Distributors', 'Linda Park', 'sales@freshfarmdist.com', '718-555-0188', 'active'),
('Household Wholesale NY', 'Marcus Hill', 'support@householdny.com', '718-555-0199', 'active');

INSERT INTO vendor_products (vendor_id, product_id, unit_purchase_cost, min_order_quantity, lead_time_days) VALUES
(1, 1, 4.10, 20, 2),
(1, 2, 2.70, 12, 3),
(1, 3, 1.85, 24, 2),
(2, 4, 0.42, 50, 1),
(2, 5, 3.20, 10, 2),
(3, 6, 5.75, 8, 4);

INSERT INTO purchase_orders (vendor_id, store_id, order_date, expected_date, received_date, order_status) VALUES
(1, 1, '2026-07-15', '2026-07-17', '2026-07-17', 'received'),
(2, 1, '2026-07-16', '2026-07-17', '2026-07-18', 'received'),
(3, 2, '2026-07-16', '2026-07-20', '2026-07-20', 'received');

INSERT INTO purchase_order_items (
    purchase_order_id, vendor_product_id, quantity_ordered, quantity_received,
    quantity_damaged, quantity_missing, unit_purchase_cost
) VALUES
(1, 1, 50, 50, 0, 0, 4.10),
(1, 3, 40, 38, 2, 2, 1.85),
(2, 4, 80, 78, 1, 2, 0.42),
(2, 5, 24, 24, 0, 0, 3.20),
(3, 6, 16, 15, 1, 1, 5.75);

INSERT INTO deliveries (purchase_order_id, delivery_date, delivery_status, notes) VALUES
(1, '2026-07-17', 'partial', 'Chips order had damaged and missing units'),
(2, '2026-07-18', 'partial', 'Produce delivery arrived one day late'),
(3, '2026-07-20', 'partial', 'One paper towel pack damaged');

INSERT INTO sales_transactions (
    store_id, sale_time, sale_status, subtotal_amount, discount_amount,
    tax_amount, refund_amount, total_amount
) VALUES
(1, '2026-07-20 09:15', 'completed', 15.77, 0.00, 1.41, 0.00, 17.18),
(1, '2026-07-20 13:40', 'completed', 14.77, 1.00, 1.24, 0.00, 15.01),
(2, '2026-07-20 12:05', 'completed', 18.47, 0.00, 1.65, 0.00, 20.12),
(2, '2026-07-20 17:30', 'partially_refunded', 13.98, 0.00, 1.25, 4.99, 15.23);

INSERT INTO sales_items (sale_id, product_id, quantity_sold, unit_retail_price, item_discount) VALUES
(1, 1, 1, 6.99, 0.00),
(1, 3, 2, 3.29, 0.00),
(1, 4, 3, 0.79, 0.00),
(2, 2, 1, 4.49, 0.50),
(2, 5, 2, 4.99, 0.50),
(3, 6, 1, 8.99, 0.00),
(3, 3, 2, 3.29, 0.00),
(3, 4, 4, 0.79, 0.00),
(4, 5, 2, 4.99, 0.00),
(4, 1, 1, 6.99, 0.00);

INSERT INTO payments (sale_id, payment_method, payment_amount, payment_time) VALUES
(1, 'credit_card', 17.18, '2026-07-20 09:16'),
(2, 'mobile_pay', 15.01, '2026-07-20 13:41'),
(3, 'debit_card', 20.12, '2026-07-20 12:06'),
(4, 'cash', 15.23, '2026-07-20 17:31');


INSERT INTO customer_returns (
    sale_item_id, processed_by_employee_id, return_time,
    quantity_returned, refund_amount, return_reason
) VALUES
(9, 5, '2026-07-21 10:30', 1, 4.99, 'Customer returned one gallon of milk');

INSERT INTO operating_expenses (store_id, expense_date, expense_type, amount, description) VALUES
(1, '2026-07-01', 'rent', 7200.00, 'Monthly rent for Flushing store'),
(1, '2026-07-10', 'utilities', 980.50, 'Electricity and water'),
(1, '2026-07-18', 'maintenance', 320.00, 'Refrigerator repair'),
(2, '2026-07-01', 'rent', 6800.00, 'Monthly rent for Jamaica store'),
(2, '2026-07-11', 'utilities', 870.25, 'Electricity and water'),
(2, '2026-07-19', 'supplies', 210.75, 'Cleaning and office supplies');
