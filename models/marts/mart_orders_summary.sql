WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
revenues AS (
    SELECT * FROM {{ ref('int_order_revenues') }}
)
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    LOWER(TRIM(o.order_status)) AS order_status,
    COALESCE(r.total_items, 0)   AS total_items,
    COALESCE(r.total_revenue, 0) AS total_revenue
FROM orders AS o
LEFT JOIN revenues AS r
    ON o.order_id = r.order_id
WHERE o.order_date IS NOT NULL