WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),
customer_orders AS (
    SELECT * FROM {{ ref('int_customer_orders') }}
)
SELECT
    c.customer_id,
    c.customer_name,
    c.email,
    co.first_order_date,
    co.last_order_date,
    COALESCE(co.total_orders, 0)  AS total_orders,
    COALESCE(co.total_revenue, 0) AS total_revenue,
    CASE
        WHEN COALESCE(co.total_orders, 0) < 2        THEN 'Nuevo'
        WHEN COALESCE(co.total_revenue, 0) > 5000    THEN 'VIP'
        WHEN COALESCE(co.total_revenue, 0) > 500     THEN 'Regular'
        ELSE 'Nuevo'
    END AS customer_segment
FROM customers AS c
LEFT JOIN customer_orders AS co
    ON c.customer_id = co.customer_id