-- Metabase variables:
--   {{start_date}}, {{end_date}}, {{store_name}}
-- The dashboard intentionally does not include the former
-- "Actual Labor Hours by Job Role" card.

WITH attendance AS (
    SELECT
        COUNT(*) FILTER (
            WHERE sh.shift_status IN ('completed', 'missed')
        ) AS scheduled_shifts,
        COUNT(*) FILTER (
            WHERE sh.shift_status = 'completed'
        ) AS completed_shifts,
        COUNT(*) FILTER (
            WHERE sh.shift_status = 'missed'
        ) AS absent_shifts,
        COUNT(*) FILTER (
            WHERE sh.shift_status = 'completed'
              AND sh.actual_start > sh.scheduled_start + INTERVAL '5 minutes'
        ) AS late_arrivals,
        ROUND(
            SUM(
                CASE
                    WHEN sh.shift_status = 'completed'
                     AND sh.actual_start IS NOT NULL
                     AND sh.actual_end IS NOT NULL
                    THEN EXTRACT(EPOCH FROM (sh.actual_end - sh.actual_start)) / 3600.0
                    ELSE 0
                END
            ),
            1
        ) AS completed_labor_hours
    FROM abc_foodmart.staff_shifts AS sh
    JOIN abc_foodmart.stores AS s
      ON s.store_id = sh.store_id
    WHERE 1 = 1
      [[AND sh.scheduled_start::date >= {{start_date}}]]
      [[AND sh.scheduled_start::date <= {{end_date}}]]
      [[AND {{store_name}}]]
)
SELECT
    scheduled_shifts,
    completed_shifts,
    absent_shifts,
    late_arrivals,
    completed_labor_hours,
    ROUND(100.0 * completed_shifts / NULLIF(scheduled_shifts, 0), 2)
        AS attendance_rate_pct,
    ROUND(100.0 * late_arrivals / NULLIF(completed_shifts, 0), 2)
        AS late_arrival_rate_pct
FROM attendance;
