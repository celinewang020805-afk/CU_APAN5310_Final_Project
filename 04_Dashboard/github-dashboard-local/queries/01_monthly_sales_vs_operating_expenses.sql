-- Metabase variables:
--   {{start_date}}  Date, optional
--   {{end_date}}    Date, optional
--   {{store_name}}  Field filter mapped to abc_foodmart.stores.store_name

WITH sales AS (
    SELECT
        DATE_TRUNC('month', st.sale_time)::date AS month,
        SUM(
            CASE
                WHEN st.total_amount > 0 THEN
                    st.subtotal_amount
                    - st.discount_amount
                    - ROUND(
                        st.refund_amount
                        * (st.subtotal_amount - st.discount_amount)
                        / st.total_amount,
                        2
                    )
                ELSE 0
            END
        ) AS net_sales
    FROM abc_foodmart.sales_transactions AS st
    JOIN abc_foodmart.stores AS s
      ON s.store_id = st.store_id
    WHERE st.sale_status <> 'voided'
      [[AND st.sale_time::date >= {{start_date}}]]
      [[AND st.sale_time::date <= {{end_date}}]]
      [[AND {{store_name}}]]
    GROUP BY 1
),
expenses AS (
    SELECT
        DATE_TRUNC('month', oe.expense_date)::date AS month,
        SUM(oe.amount) AS operating_expenses
    FROM abc_foodmart.operating_expenses AS oe
    JOIN abc_foodmart.stores AS s
      ON s.store_id = oe.store_id
    WHERE 1 = 1
      [[AND oe.expense_date >= {{start_date}}]]
      [[AND oe.expense_date <= {{end_date}}]]
      [[AND {{store_name}}]]
    GROUP BY 1
)
SELECT
    COALESCE(sales.month, expenses.month) AS month,
    ROUND(COALESCE(sales.net_sales, 0), 2) AS net_sales,
    ROUND(COALESCE(expenses.operating_expenses, 0), 2) AS operating_expenses
FROM sales
FULL OUTER JOIN expenses
  ON expenses.month = sales.month
ORDER BY month;
