-- Metabase variables:
--   {{start_date}}, {{end_date}}, {{store_name}}

SELECT
    oe.expense_type,
    ROUND(SUM(oe.amount), 2) AS operating_expenses,
    ROUND(
        100.0 * SUM(oe.amount)
        / NULLIF(SUM(SUM(oe.amount)) OVER (), 0),
        1
    ) AS expense_share_pct
FROM abc_foodmart.operating_expenses AS oe
JOIN abc_foodmart.stores AS s
  ON s.store_id = oe.store_id
WHERE 1 = 1
  [[AND oe.expense_date >= {{start_date}}]]
  [[AND oe.expense_date <= {{end_date}}]]
  [[AND {{store_name}}]]
GROUP BY oe.expense_type
ORDER BY operating_expenses DESC;
