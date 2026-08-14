-- Metabase variables:
--   {{start_date}}, {{end_date}}, {{store_name}}

WITH returns AS (
    SELECT sale_item_id, SUM(refund_amount) AS refund_amount
    FROM abc_foodmart.customer_returns
    GROUP BY sale_item_id
),
category_sales AS (
    SELECT
        pc.category_name,
        SUM(
            si.quantity_sold * si.unit_retail_price
            - si.item_discount
            - COALESCE(r.refund_amount, 0)
        ) AS net_merchandise_sales
    FROM abc_foodmart.sales_transactions AS st
    JOIN abc_foodmart.sales_items AS si
      ON si.sale_id = st.sale_id
    JOIN abc_foodmart.products AS p
      ON p.product_id = si.product_id
    JOIN abc_foodmart.product_categories AS pc
      ON pc.category_id = p.category_id
    JOIN abc_foodmart.stores AS s
      ON s.store_id = st.store_id
    LEFT JOIN returns AS r
      ON r.sale_item_id = si.sale_item_id
    WHERE st.sale_status <> 'voided'
      [[AND st.sale_time::date >= {{start_date}}]]
      [[AND st.sale_time::date <= {{end_date}}]]
      [[AND {{store_name}}]]
    GROUP BY pc.category_name
)
SELECT
    category_name,
    ROUND(net_merchandise_sales, 2) AS net_merchandise_sales,
    ROUND(
        100.0 * net_merchandise_sales
        / NULLIF(SUM(net_merchandise_sales) OVER (), 0),
        1
    ) AS sales_share_pct
FROM category_sales
ORDER BY net_merchandise_sales DESC;
