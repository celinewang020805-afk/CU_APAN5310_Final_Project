-- Metabase variables:
--   {{start_date}}, {{end_date}}, {{store_name}}

WITH period_bounds AS (
    SELECT
        COALESCE(
            MIN(st.sale_time::date) FILTER (
                WHERE st.sale_status <> 'voided'
                [[AND st.sale_time::date >= {{start_date}}]]
                [[AND st.sale_time::date <= {{end_date}}]]
            ),
            MIN(st.sale_time::date) FILTER (WHERE st.sale_status <> 'voided')
        ) AS period_start,
        COALESCE(
            MAX(st.sale_time::date) FILTER (
                WHERE st.sale_status <> 'voided'
                [[AND st.sale_time::date >= {{start_date}}]]
                [[AND st.sale_time::date <= {{end_date}}]]
            ),
            MAX(st.sale_time::date) FILTER (WHERE st.sale_status <> 'voided')
        ) AS period_end
    FROM abc_foodmart.sales_transactions AS st
),
returned_units AS (
    SELECT cr.sale_item_id, SUM(cr.quantity_returned) AS quantity_returned
    FROM abc_foodmart.customer_returns AS cr
    WHERE 1 = 1
      [[AND cr.return_time::date <= {{end_date}}]]
    GROUP BY cr.sale_item_id
),
products_in_scope AS (
    SELECT DISTINCT p.product_id, p.product_name
    FROM abc_foodmart.store_inventory AS inv
    JOIN abc_foodmart.products AS p
      ON p.product_id = inv.product_id
    JOIN abc_foodmart.stores AS s
      ON s.store_id = inv.store_id
    WHERE p.active_flag = TRUE
      [[AND {{store_name}}]]
),
sales_in_period AS (
    SELECT
        si.product_id,
        SUM(GREATEST(si.quantity_sold - COALESCE(ru.quantity_returned, 0), 0))
            AS net_units_sold
    FROM abc_foodmart.sales_transactions AS st
    JOIN abc_foodmart.sales_items AS si
      ON si.sale_id = st.sale_id
    JOIN abc_foodmart.stores AS s
      ON s.store_id = st.store_id
    LEFT JOIN returned_units AS ru
      ON ru.sale_item_id = si.sale_item_id
    WHERE st.sale_status <> 'voided'
      [[AND st.sale_time::date >= {{start_date}}]]
      [[AND st.sale_time::date <= {{end_date}}]]
      [[AND {{store_name}}]]
    GROUP BY si.product_id
)
SELECT
    pis.product_name,
    COALESCE(sip.net_units_sold, 0)::integer AS net_units_sold,
    ROUND(
        COALESCE(sip.net_units_sold, 0)::numeric
        / NULLIF((pb.period_end - pb.period_start + 1), 0),
        2
    ) AS average_daily_units_sold
FROM products_in_scope AS pis
CROSS JOIN period_bounds AS pb
LEFT JOIN sales_in_period AS sip
  ON sip.product_id = pis.product_id
ORDER BY
    average_daily_units_sold ASC,
    net_units_sold ASC,
    pis.product_name ASC
LIMIT 10;
