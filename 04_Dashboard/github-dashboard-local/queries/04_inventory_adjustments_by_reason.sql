-- Metabase variables:
--   {{start_date}}, {{end_date}}, {{store_name}}

WITH grouped AS (
    SELECT
        ia.adjustment_type,
        SUM(ia.quantity_delta) AS net_units
    FROM abc_foodmart.inventory_adjustments AS ia
    JOIN abc_foodmart.stores AS s
      ON s.store_id = ia.store_id
    WHERE 1 = 1
      [[AND ia.adjustment_time::date >= {{start_date}}]]
      [[AND ia.adjustment_time::date <= {{end_date}}]]
      [[AND {{store_name}}]]
    GROUP BY ia.adjustment_type
)
SELECT adjustment_type, net_units
FROM (
    SELECT
        INITCAP(REPLACE(adjustment_type, '_', ' ')) AS adjustment_type,
        net_units,
        ABS(net_units) AS sort_order
    FROM grouped

    UNION ALL

    SELECT 'No adjustments in selected period', 0, 0
    WHERE NOT EXISTS (SELECT 1 FROM grouped)
) AS results
ORDER BY sort_order DESC, adjustment_type;
