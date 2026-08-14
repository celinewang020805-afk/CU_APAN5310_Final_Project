-- ABC Foodmart object patch for an existing Checkpoint 3 database.
-- This changes no tables, columns, keys, or relationships. It replaces the
-- three trigger functions and the two approved analytical view definitions.

CREATE OR REPLACE FUNCTION abc_foodmart.apply_inventory_adjustment()
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
        RAISE EXCEPTION 'Inventory cannot be negative for store %, product %',
            NEW.store_id, NEW.product_id;
    END IF;

    UPDATE abc_foodmart.store_inventory
    SET quantity_on_hand = new_quantity
    WHERE store_id = NEW.store_id AND product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION abc_foodmart.reduce_inventory_after_sale()
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

CREATE OR REPLACE FUNCTION abc_foodmart.validate_purchase_order_vendor()
RETURNS TRIGGER AS $$
DECLARE
    po_vendor_id BIGINT;
    item_vendor_id BIGINT;
BEGIN
    SELECT vendor_id
    INTO po_vendor_id
    FROM abc_foodmart.purchase_orders
    WHERE purchase_order_id = NEW.purchase_order_id;

    SELECT vendor_id
    INTO item_vendor_id
    FROM abc_foodmart.vendor_products
    WHERE vendor_product_id = NEW.vendor_product_id;

    IF po_vendor_id <> item_vendor_id THEN
        RAISE EXCEPTION 'Purchase order item vendor must match purchase order vendor';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW abc_foodmart.daily_store_sales AS
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
FROM abc_foodmart.sales_transactions st
JOIN abc_foodmart.stores s ON s.store_id = st.store_id
WHERE st.sale_status <> 'voided'
GROUP BY s.store_name, st.sale_time::DATE;

CREATE OR REPLACE VIEW abc_foodmart.vendor_performance_summary AS
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
    FROM abc_foodmart.purchase_orders po
    JOIN abc_foodmart.purchase_order_items poi
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
FROM abc_foodmart.vendors v
JOIN purchase_order_level pol ON pol.vendor_id = v.vendor_id
GROUP BY v.vendor_name;
